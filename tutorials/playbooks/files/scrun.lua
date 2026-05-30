local json = require 'json'
local open = io.open

local function read_file(path)
        local file = open(path, "rb")
        if not file then return nil end
        local content = file:read "*all"
        file:close()
        return content
end

local function write_file(path, contents)
        local file = open(path, "wb")
        if not file then return nil end
        file:write(contents)
        file:close()
        return
end

local function run_cmd(env_prefix, cmd)
        local full_cmd = env_prefix .. cmd
        local status, output = slurm.allocator_command(full_cmd)
        if status ~= 0 then
                slurm.log_info(string.format("run_cmd failed: %s -> exit %d", full_cmd, status))
                if output and output ~= "" then
                        slurm.log_info(string.format("  output: %s", output))
                end
        else
                slurm.log_debug(string.format("run_cmd: %s -> exit 0", full_cmd))
        end
        return status, output
end

local function get_user_info(user_id)
        local status, user = slurm.allocator_command(string.format("/usr/bin/id -un %d", user_id))
        if status ~= 0 or not user or user == "" then
                slurm.log_info(string.format("get_user_info: failed to resolve username for user_id=%s", tostring(user_id)))
                return nil, nil, nil
        end
        user = string.gsub(user, "%s+", "")
        local home_dir = os.getenv("HOME")
        if not home_dir or home_dir == "" or home_dir == "/root" then
                local status_home, home_dir_out = slurm.allocator_command(string.format("/usr/bin/getent passwd %q | cut -d: -f6", user))
                if status_home == 0 and home_dir_out and home_dir_out ~= "" then
                        home_dir = string.gsub(home_dir_out, "%s+", "")
                else
                        home_dir = "/home/" .. user
                end
        end
        local env_prefix = string.format("HOME=%q PATH=/usr/bin:/bin:/usr/sbin:/sbin ", home_dir)
        return user, home_dir, env_prefix
end

function slurm_scrun_stage_in(id, bundle, spool_dir, config_file, job_id, user_id, group_id, job_env)
        slurm.log_debug(string.format("stage_in called: id=%s, bundle=%s, spool_dir=%s, config_file=%s, job_id=%d, user_id=%d, group_id=%d",
                       id, bundle, spool_dir, config_file, job_id, user_id, group_id))

        local status, output, user, rc
        local file_content = read_file(config_file)
        if not file_content then
                slurm.log_info("stage_in: config_file could not be read: " .. tostring(config_file))
                return slurm.ERROR
        end
        local config = json.decode(file_content)
        local src_rootfs = config["root"]["path"]

        local user, home_dir, env_prefix = get_user_info(user_id)
        if not user then
                return slurm.ERROR
        end

        -- Since /home is shared, we use the user's home directory for OCI config spooling.
        -- NOTE: The "id" parameter supplied by the Slurm scrun plugin is guaranteed by Slurm to
        -- be unique across concurrent jobs and steps for the same user, preventing folder collisions.
        local root = home_dir .. "/.scrun/"
        local dst_bundle = root .. "/" .. id .. "/"
        local dst_config = root .. "/" .. id .. "/config.json"
        local dst_rootfs = src_rootfs

        if string.sub(src_rootfs, 1, 1) ~= "/"
        then
                -- always use absolute path
                src_rootfs = string.format("%s/%s", bundle, src_rootfs)
                dst_rootfs = src_rootfs
        end

        -- Ensure local parent dir exists on the allocator (already shared with compute nodes via /home)
        -- Enforce strict 700 permissions to lock down access to the OCI bundle.
        -- Shell quote paths with %q for path robustness against special characters.
        status, output = run_cmd(env_prefix, string.format("mkdir -p -m 700 %q", root))
        if (status == 0) then
                status, output = run_cmd(env_prefix, string.format("mkdir -p -m 700 %q", root .. "/" .. id))
        end
        if (status ~= 0) then
                slurm.log_info("Failed to create shared directory on allocator: " .. tostring(output))
                return slurm.ERROR
        end

        slurm.set_bundle_path(dst_bundle)
        slurm.set_root_path(dst_rootfs)

        config["root"]["path"] = dst_rootfs

        -- Always force user namespace support in container or runc will reject
        local process_user_id = 0
        local process_group_id = 0

        if ((config["process"] ~= nil) and (config["process"]["user"] ~= nil))
        then
                -- resolve out user in the container
                if (config["process"]["user"]["uid"] ~= nil)
                then
                        process_user_id=config["process"]["user"]["uid"]
                else
                        process_user_id=0
                end

                -- resolve out group in the container
                if (config["process"]["user"]["gid"] ~= nil)
                then
                        process_group_id=config["process"]["user"]["gid"]
                else
                        process_group_id=0
                end

                -- purge additionalGids as they are not supported in rootless
                if (config["process"]["user"]["additionalGids"] ~= nil)
                then
                        config["process"]["user"]["additionalGids"] = nil
                end
        end

        if (config["linux"] ~= nil)
        then
                -- force user namespace to always be defined for rootless mode
                local found = false
                if (config["linux"]["namespaces"] == nil)
                then
                        config["linux"]["namespaces"] = {}
                else
                        for _, namespace in ipairs(config["linux"]["namespaces"]) do
                                if (namespace["type"] == "user")
                                then
                                        found=true
                                        break
                                end
                        end
                end
                if (found == false)
                then
                        table.insert(config["linux"]["namespaces"], {type= "user"})
                end

                -- Provide default user/group mappings. The "true or" forces mapping overwrite, which is
                -- intentional in this laboratory setup to ensure rootless execution "just works"
                -- by mapping container root directly to the host user/group. Remove the "true or"
                -- if you wish to support complex, pre-defined subuid/subgid mappings from the OCI config.
                if (true or config["linux"]["uidMappings"] == nil)
                then
                        config["linux"]["uidMappings"] =
                                {{containerID=process_user_id, hostID=math.floor(user_id), size=1}}
                end

                if (true or config["linux"]["gidMappings"] == nil)
                then
                        config["linux"]["gidMappings"] =
                                {{containerID=process_group_id, hostID=math.floor(group_id), size=1}}
                end

                -- disable trying to use a specific cgroup
                config["linux"]["cgroupsPath"] = nil
        end

        if (config["mounts"] ~= nil)
        then
                -- Find and remove any user/group settings in mounts
                for _, mount in ipairs(config["mounts"]) do
                        local opts = {}

                        if (mount["options"] ~= nil)
                        then
                                for _, opt in ipairs(mount["options"]) do
                                        if ((string.sub(opt, 1, 4) ~= "gid=") and (string.sub(opt, 1, 4) ~= "uid="))
                                        then
                                                table.insert(opts, opt)
                                        end
                                end
                        end

                        if (opts ~= nil and #opts > 0)
                        then
                                mount["options"] = opts
                        else
                                mount["options"] = nil
                        end
                end

                -- Remove all bind mounts by copying files into rootfs (done locally since shared filesystem is active)
                -- NOTE: Since dst_rootfs is set to src_rootfs in the Zero-Copy model, copying files into rootfs
                -- modifies the source rootfs directly. This is acceptable here because Podman's rootless container
                -- lifecycle uses temporary bundle layers, but be aware if reusing with a persistent/read-only rootfs.
                -- Shell quote paths with %q for path robustness against special characters.
                local mounts = {}
                for i, mount in ipairs(config["mounts"]) do
                        if ((mount["type"] ~= nil) and (mount["type"] == "bind") and (string.sub(mount["source"], 1, 4) ~= "/sys") and (string.sub(mount["source"], 1, 5) ~= "/proc"))
                        then
                                status, output = run_cmd(env_prefix, string.format("/usr/bin/env rsync --numeric-ids --ignore-errors --stats -a -- %q %q", mount["source"], dst_rootfs..mount["destination"]))
                                if (status ~= 0)
                                then
                                        slurm.log_info("rsync mount failed")
                                end
                        else
                                table.insert(mounts, mount)
                        end
                end
                config["mounts"] = mounts
        end

        -- Force version to one compatible with older runc/crun at risk of new features silently failing
        config["ociVersion"] = "1.0.0"

        -- Merge in Job environment into container -- this is optional!
        if (config["process"]["env"] == nil)
        then
                config["process"]["env"] = {}
        end
        for _, env in ipairs(job_env) do
                table.insert(config["process"]["env"], env)
        end

        -- Remove all prestart hooks to squash any networking attempts
        if ((config["hooks"] ~= nil) and (config["hooks"]["prestart"] ~= nil))
        then
                config["hooks"]["prestart"] = nil
        end

        -- Remove all rlimits
        if ((config["process"] ~= nil) and (config["process"]["rlimits"] ~= nil))
        then
                config["process"]["rlimits"] = nil
        end

        write_file(dst_config, json.encode(config))
        slurm.log_debug("created shared config: "..dst_config)

        return slurm.SUCCESS
end

function slurm_scrun_stage_out(id, bundle, orig_bundle, root_path, orig_root_path, spool_dir, config_file, jobid, user_id, group_id)
        if (root_path == nil)
        then
                root_path = ""
        end

        slurm.log_debug(string.format("stage_out(%s, %s, %s, %s, %s, %s, %s, %d, %d, %d)",
                       id, bundle, orig_bundle, root_path, orig_root_path, spool_dir, config_file, jobid, user_id, group_id))

        if (bundle == orig_bundle)
        then
                slurm.log_info(string.format("skipping stage_out as bundle=orig_bundle=%s", bundle))
                return slurm.SUCCESS
        end

        -- NOTE: If future cleanup tasks are added here, ensure they are resilient to user resolution failures
        -- so that failing to retrieve user info does not bypass all remaining cleanups.
        local user, home_dir, env_prefix = get_user_info(user_id)
        if not user then
                return slurm.ERROR
        end

        -- Since rootfs is shared and not copied, we only clean up the OCI config directory locally on the shared volume.
        -- Shell quote path with %q for robustness.
        run_cmd(env_prefix, string.format("/usr/bin/rm --preserve-root=all --one-file-system -dr -- %q", bundle))

        return slurm.SUCCESS
end

slurm.log_info("initialized scrun.lua")

return slurm.SUCCESS

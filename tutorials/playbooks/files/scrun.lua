local json = require 'json'
local open = io.open
local scratch_path = "/run/user/"

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

function slurm_scrun_stage_in(id, bundle, spool_dir, config_file, job_id, user_id, group_id, job_env)
        slurm.log_debug(string.format("stage_in(%s, %s, %s, %s, %d, %d, %d)",
                       id, bundle, spool_dir, config_file, job_id, user_id, group_id))

        local status, output, user, rc
        local config = json.decode(read_file(config_file))
        local src_rootfs = config["root"]["path"]
        rc, user = slurm.allocator_command(string.format("id -un %d", user_id))
        user = string.gsub(user, "%s+", "")
        local root = scratch_path..math.floor(user_id).."/slurm/scrun/"
        local dst_bundle = root.."/"..id.."/"
        local dst_config = root.."/"..id.."/config.json"
        local dst_rootfs = root.."/"..id.."/rootfs/"

        if string.sub(src_rootfs, 1, 1) ~= "/"
        then
                -- always use absolute path
                src_rootfs = string.format("%s/%s", bundle, src_rootfs)
        end

        status, output = slurm.allocator_command("mkdir -p "..dst_rootfs)
        if (status ~= 0)
        then
                slurm.log_info(string.format("mkdir(%s) failed %u: %s",
                               dst_rootfs, status, output))
                return slurm.ERROR
        end

        status, output = slurm.allocator_command(string.format("/usr/bin/env rsync --exclude sys --exclude proc --numeric-ids --delete-after --ignore-errors --stats -a -- %s/ %s/", src_rootfs, dst_rootfs))
        if (status ~= 0)
        then
                -- rsync can fail due to permissions which may not matter
                slurm.log_info(string.format("WARNING: rsync failed: %s", output))
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

                -- Provide default user map as root if one not provided
                if (true or config["linux"]["uidMappings"] == nil)
                then
                        config["linux"]["uidMappings"] =
                                {{containerID=process_user_id, hostID=math.floor(user_id), size=1}}
                end

                -- Provide default group map as root if one not provided
                -- mappings fail with build???
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

                -- Remove all bind mounts by copying files into rootfs
                local mounts = {}
                for i, mount in ipairs(config["mounts"]) do
                        if ((mount["type"] ~= nil) and (mount["type"] == "bind") and (string.sub(mount["source"], 1, 4) ~= "/sys") and (string.sub(mount["source"], 1, 5) ~= "/proc"))
                        then
                                status, output = slurm.allocator_command(string.format("/usr/bin/env rsync --numeric-ids --ignore-errors --stats -a -- %s %s", mount["source"], dst_rootfs..mount["destination"]))
                                if (status ~= 0)
                                then
                                        -- rsync can fail due to permissions which may not matter
                                        slurm.log_info("rsync failed")
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
        slurm.log_info("created: "..dst_config)

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

        status, output = slurm.allocator_command(string.format("/usr/bin/env rsync --numeric-ids --delete-after --ignore-errors --stats -a -- %s/ %s/", root_path, orig_root_path))
        if (status ~= 0)
        then
                -- rsync can fail due to permissions which may not matter
                slurm.log_info("rsync failed")
        else
                -- cleanup temporary after they have been synced backed to source
                slurm.allocator_command(string.format("/usr/bin/rm --preserve-root=all --one-file-system -dr -- %s", bundle))
        end

        return slurm.SUCCESS
end

slurm.log_info("initialized scrun.lua")

return slurm.SUCCESS

function plan = buildfile()
%BUILDFILE Use with buildtool <test,check,archive,doc,build>

    % Require R2023b or newer
    if ~ismember(exist('isMATLABReleaseOlderThan'), [2,5]) ...
            || isMATLABReleaseOlderThan('R2023b') %#ok<EXIST>
        error("Build requires R2023b or later");
    end
    
    import matlab.buildtool.tasks.CodeIssuesTask
    import matlab.buildtool.tasks.TestTask
    
    % Setup build plan
    plan = buildplan(localfunctions);
    plan.DefaultTasks = "test";

    % Standard tasks
    plan("check") = CodeIssuesTask;
    plan("test") = TestTask;

    % Dependencies
    plan("archive").Dependencies = ["check", "test", "doc"];
    plan("build").Dependencies = ["check", "test", "doc", "updateVersion"];
    plan("updateVersion").Dependencies = ["genPrjFile"];
end

function archiveTask(~)
    % Create ZIP file of source
    %   include current commit hash (first 8 chars)
    filename = "source_" + gitrepo().LastCommit.ID.extractBefore(9);
    zip(filename,"*")
end

function genPrjFileTask(~)
    % Generate toolboxPackaging.prj from template
    root = xmlread("toolboxPackaging.prj.template");
    
    % Set configuration file
    prj = root.getElementsByTagName("deployment-project").item(0);
    cfg = prj.getElementsByTagName("configuration").item(0);
    cfg.setAttribute("file", java.lang.String(pwd()).concat(cfg.getAttribute("file")));
    cfg.setAttribute("location", pwd());

    % Write to file
    xmlwrite("toolboxPackaging.prj", root);
end

function updateVersionTask(~)
    % Take version from pyproject.toml
    fid = fopen(fullfile("..", "pyproject.toml"),'r');
    ver = [];
    while ~feof(fid)
        line = string(fgets(fid)).strip();
        ver = regexp(line, "version\s*=\s*""([^""]+)""", "tokens");
        if ~isempty(ver)
            ver = ver{1};
            fprintf("Found version: %s\n", ver);
            break;
        end
    end
    fclose(fid);

    if isempty(ver)
        error("Could not find version string in pyproject.toml");
    end

    % Replace in toolboxPackaging.prj
    ver = [ver.split('.'); repelem("0", 3 - ver.count('.'), 1)];
    old = matlab.addons.toolbox.toolboxVersion("toolboxPackaging.prj");
    old = string(old).split('.');
    ver(4) = string(int32(str2double(old(end))) + int32(1));
    ver = join(ver, ".");
    fprintf("Setting version to %s\n", ver);
    matlab.addons.toolbox.toolboxVersion("toolboxPackaging.prj", join(ver, "."));
end

function buildTask(~)
    % Build project
    matlab.addons.toolbox.packageToolbox("toolboxPackaging.prj");
end

function docTask(~)
    % Generate documentation
    rootDir = pwd();

    docDir = fullfile(rootDir,"toolbox","doc");
    htmlDir = fullfile(docDir,"html");
    mlxFileInfo = dir(fullfile(docDir,"*.mlx"));
    mlxFiles = string({mlxFileInfo.name}');
    for iFile = 1:size(mlxFiles,1)
        [~, filename] = fileparts(mlxFiles(iFile));
        export(fullfile(docDir,mlxFiles(iFile)),fullfile(htmlDir,filename + ".html"));
    end
end
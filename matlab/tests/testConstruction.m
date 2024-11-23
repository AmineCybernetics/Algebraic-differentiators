%% Main function to generate tests
function tests = testConstruction()
    tests = functiontests(localfunctions);
end

%% Test Functions
function testWorks(testCase)
    % Check can construct instance
    testCase.verifyInstanceOf(AlgDiff(0.001, 1, 1, 0, FilterWindowLength=2), "AlgDiff");
    testCase.verifyInstanceOf(AlgDiff(0.001, 1, 1, 0, FilterWindowLength=2, Correction=false), "AlgDiff");
    testCase.verifyInstanceOf(AlgDiff(0.001, 1, 1, 0, CutoffFrequency=2*pi), "AlgDiff");
    testCase.verifyInstanceOf(AlgDiff(0.001, 1, 1, 0, CutoffFrequency=2*pi, Correction=false), "AlgDiff");
end

function testWrongArguments(testCase)
    function run(alpha, beta, N, T, wc)
        try
            AlgDiff(0.001, alpha, beta, N, ...
                FilterWindowLength=T, CutoffFrequency=wc);
            testCase.verifyFail();
        catch
            % Ignore
        end
    end

    % T < ts
    run(0, 0, 1, 0.0001, []);
end

%% Setup & Teardown 
function setupOnce(testCase)
    testCase.TestData.origPath = addpath(genpath(fullfile('..', 'toolbox')));
end

function teardownOnce(testCase)
    path(testCase.TestData.origPath);
end
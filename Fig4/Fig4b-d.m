%% 4 LME models for R1 / MBP / MAP2 with random effects by ID
% Adds subject-specific lines (colored by Age) for random-slope models:
%   M3: R1 ~ MBP  + (MBP|ID)
%   M4: R1 ~ MAP2 + (MAP2|ID)

clear; close all; clc;

%% ---------- Load data ----------
filePath = 'grant_correlation_for_MBP-MAP2.csv';
%filePath = 'grant_correlation_for_MBP-MAP2_030626.csv';
T = readtable(filePath);

% %reqVars = {'R1','MBP','MAP2','Age','ID'};
% %missingVars = setdiff(reqVars, T.Properties.VariableNames);
% if ~isempty(missingVars)
%     error('Missing required columns in CSV: %s', strjoin(missingVars, ', '));
% end
%T = rmmissing(T(:, reqVars));
JJ = find(T.Age>6); %% infants
T = T(JJ,:)

T.ID = categorical(T.ID);

%% ---------- Age colors (plasma) ----------
[cmap, ptColors, cbInfo] = makeAgeColors(T.Age, 256);
% make colormap by depth
ndepths=numel(unique(T.depth));
T.depth=100-T.depth; % flip so deeper are lower values
[cmap, ptColors, cbInfo] = makeAgeColors(T.depth, ndepths);
%% ---------- Define and fit models ----------
modelSpecs = { ...
    struct('name','R1 ~ MBP*MAP2 + (1|ID)',        'formula','R1 ~ MBP*MAP2 + (1|ID)',        'type','interaction'), ...
    struct('name','R1 ~ MBP + MAP2 + (MAP2|ID)',    'formula','R1 ~ MBP + MAP2 + (MAP2|ID)',      'type','additive','randomSlope',true), ...
    struct('name','R1 ~ MBP + (MBP|ID)',           'formula','R1 ~ MBP + (MBP|ID)',           'type','single','xvar','MBP','randomSlope',true), ...
    struct('name','R1 ~ MBP + (1|ID)',             'formula','R1 ~ MBP + (1|ID)',           'type','single','xvar','MBP','randomSlope',false), ...
    struct('name','R1 ~ MAP2 + (1|ID)',         'formula','R1 ~ MAP2+ (1|ID)',         'type','single','xvar','MAP2','randomSlope',false) ...  
    };

lmeList = cell(size(modelSpecs));
for i = 1:numel(modelSpecs)
    lmeList{i} = fitlme(T, modelSpecs{i}.formula);
end
 cmp1 = compare(lmeList{4},lmeList{3});  % 
 disp(cmp1)
 cmp2 = compare(lmeList{4}, lmeList{2});  % 
 disp(cmp2)




%% ---------- Write results to text file ----------
outTxt = fullfile(pwd, 'LME_results_R1_MBP_MAP2.txt');
fid = fopen(outTxt, 'w');
if fid < 0, error('Could not open output file for writing: %s', outTxt); end

fprintf(fid, 'LME results written on %s\n', datestr(now));
fprintf(fid, 'Data file: %s\n', filePath);
fprintf(fid, 'N rows used: %d\n\n', height(T));

for i = 1:numel(modelSpecs)
    spec = modelSpecs{i};
    lme  = lmeList{i};

    fprintf(fid, '============================================================\n');
    fprintf(fid, '%s\n', spec.name);
    fprintf(fid, 'Formula: %s\n\n', spec.formula);

    fprintf(fid, '%s\n', evalc('disp(lme)'));
    fprintf(fid, '\n-- Fixed effects (Coefficients) --\n%s\n', evalc('disp(lme.Coefficients)'));

    fprintf(fid, '\n-- ANOVA --\n');
    try
        fprintf(fid, '%s\n', evalc('disp(anova(lme))'));
    catch
        fprintf(fid, 'ANOVA not available in this MATLAB version.\n');
    end

    fprintf(fid, '\n-- Random effects covariance parameters --\n');
    try
        fprintf(fid, '%s\n', evalc('disp(lme.covarianceParameters)'));
    catch
        fprintf(fid, 'covarianceParameters not available.\n');
    end

    fprintf(fid, '\n\n');
end
fclose(fid);
fprintf('Wrote LME results to: %s\n', outTxt);

%% ---------- Plot: one figure per model ----------
for i = 1:numel(modelSpecs)
    spec = modelSpecs{i};
    lme  = lmeList{i};

   
    switch spec.type
        case 'interaction'
            f=figure('Color','w','Units','normalized','Position',[ 0 0 .5 .5]);
            subplot(1,2,1);
            plotEffectPanel(lme, T, ptColors, cmap, cbInfo, 'MBP', 'MAP2', 'interaction', spec.name);

            subplot(1,2,2);
            plotEffectPanel(lme, T, ptColors, cmap, cbInfo, 'MAP2', 'MBP', 'interaction', spec.name);

            sgtitle(spec.name, 'Interpreter','none');

        case 'additive'
            f=figure('Color','w','Units','normalized','Position',[ 0 0 .5 .5]);
            subplot(1,2,1);
            plotEffectPanel(lme, T, ptColors, cmap, cbInfo, 'MBP', 'MAP2', 'additive', spec.name);

            subplot(1,2,2);
            plotEffectPanel(lme, T, ptColors, cmap, cbInfo, 'MAP2', 'MBP', 'additive', spec.name);

            sgtitle(spec.name, 'Interpreter','none');

        case 'single'
            f=figure('Color','w','Units','normalized','Position',[ 0 0 .25 .5]);
            % If randomSlope=true, add subject-specific lines (Conditional=true)
            if isfield(spec,'randomSlope') && spec.randomSlope
                plotRandomSlopeModel(lme, T, ptColors, cmap, cbInfo, spec.xvar, spec.name);
            else
                plotEffectPanel(lme, T, ptColors, cmap, cbInfo, spec.xvar, '', 'single', spec.name);
            end
            %sgtitle(spec.name, 'Interpreter','none');

        otherwise
            error('Unknown model type: %s', spec.type);
    end
    % Export  figure as 600 dpi PNG
    outPngSum = fullfile(pwd, [spec.name '.png']);
    exportgraphics(f, outPngSum, 'Resolution', 600);

end

%% ======================= Local functions =======================

function plotRandomSlopeModel(lme, T, ptColors, cmap, cbInfo, xVar, modelLabel)
% For models like: R1 ~ x + (x|ID)
% - Scatter colored by row Age (ptColors)
% - Subject-specific lines (Conditional=true) colored by *mean Age per ID*
% - Population-level fit (Conditional=false) + 95% CI overlaid in black/gray
    hold on;
    markerSize=100;
    % Scatter
    scatter(T.(xVar), T.R1, markerSize, ptColors, 'filled', 'MarkerFaceAlpha', 0.80);

    % ---- Subject-specific lines ----
    ids = categories(T.ID);
    nGrid = 60;

    for k = 1:numel(ids)
        thisID = ids{k};
        idx = (T.ID == thisID);
        if nnz(idx) < 2
            % not enough points to visually justify a line; skip
            continue;
        end

        xk = T.(xVar)(idx);
        xGrid = linspace(min(xk), max(xk), nGrid)';

        newT = table();
        newT.(xVar) = xGrid;
        newT.ID = repmat(categorical({thisID}), size(xGrid));

        % Subject-specific prediction including random effects:
        yhat_k = predict(lme, newT, 'Conditional', true);

        % Color by mean Age of that ID
        age_k = mean(doubleifyAge(T.Age(idx)));
        lineColor = ageToColor(age_k, cmap, cbInfo);

        plot(xGrid, yhat_k, '-', 'Color', lineColor, 'LineWidth', 1.2);
    end

    % ---- Population-level fit + 95% CI ----
    xAll = T.(xVar);
    xGridAll = linspace(min(xAll), max(xAll), 200)';

    newAll = table();
    newAll.(xVar) = xGridAll;
    newAll.ID = repmat(T.ID(1), size(xGridAll)); % dummy valid level

    [yhatPop, yCIPop] = predict(lme, newAll, 'Conditional', false, 'Alpha', 0.05);

    fill([xGridAll; flipud(xGridAll)], [yCIPop(:,1); flipud(yCIPop(:,2))], ...
        [0.5 0.5 0.5], 'FaceAlpha', 0.18, 'EdgeColor', 'none');
    plot(xGridAll, yhatPop, 'k-', 'LineWidth', 2);

    xlabel(xVar); ylabel('R_1 [s^{-1}]');
    set(gca,'FontName','Avenir','FontSize',18)
    applyAgeColorbar(cmap, cbInfo);
    applydepthColorbar(cmap,cbInfo);
 box off;

    % Title with coefficient + p-value (fixed effect for xVar)
    coefTbl = lme.Coefficients;
    b = getCoef(coefTbl, xVar);
    p = getPval(coefTbl, xVar);
    title(sprintf('%s: %s \\beta=%.3g, p=%.3g', modelLabel, xVar, b, p), 'Interpreter','tex','FontSize',12);
end

function plotEffectPanel(lme, T, ptColors, cmap, cbInfo, xVar, holdVar, mode, modelLabel)
    coefTbl = lme.Coefficients;

    x = T.(xVar);
    y = T.R1;
    markerSize=100;
    scatter(x, y, markerSize, ptColors, 'filled', 'MarkerFaceAlpha', 0.85); hold on;

    xGrid = linspace(min(x), max(x), 200)';

    newT = table();
    newT.(xVar) = xGrid;

    if ~isempty(holdVar)
        holdMean = mean(T.(holdVar));
        newT.(holdVar) = repmat(holdMean, size(xGrid));
    end

    newT.ID = repmat(T.ID(1), size(xGrid));

    [yhat, yCI] = predict(lme, newT, 'Conditional', false, 'Alpha', 0.05);

    fill([xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
        [0.5 0.5 0.5], 'FaceAlpha', 0.20, 'EdgeColor', 'none');
    plot(xGrid, yhat, 'k-', 'LineWidth', 2);

    xlabel(xVar); ylabel('R_1[s^{-1}]');
    set(gca,'FontName','Avenir','FontSize',18)
%    applyAgeColorbar(cmap, cbInfo);
    applydepthColorbar(cmap,cbInfo);
     box off;

    switch mode
        case 'single'
            b = getCoef(coefTbl, xVar); p = getPval(coefTbl, xVar);
            title(sprintf('%s: \\beta=%.3g, p=%.3g', xVar, b, p), 'Interpreter','tex','FontSize',12);

        case 'additive'
            b = getCoef(coefTbl, xVar); p = getPval(coefTbl, xVar);
            holdMean = mean(T.(holdVar));
            title(sprintf('%s (hold %s=%.3g): \\beta=%.3g, p=%.3g', ...
                xVar, holdVar, holdMean, b, p), 'Interpreter','tex','FontSize',12);

        case 'interaction'
            b_main = getCoef(coefTbl, xVar);
            p_main = getPval(coefTbl, xVar);

            intName = interactionTermName(xVar, holdVar, coefTbl.Name);
            b_int = getCoef(coefTbl, intName);
            p_int = getPval(coefTbl, intName);

            holdMean = mean(T.(holdVar));
            effSlope = b_main + b_int * holdMean;

            title(sprintf(['%s (hold %s=%.3g)\n' ...
                           '%s: \\beta=%.3g, p=%.3g | %s: \\beta=%.3g, p=%.3g | Eff.slope=%.3g'], ...
                           xVar, holdVar, holdMean, ...
                           xVar, b_main, p_main, intName, b_int, p_int, effSlope), ...
                           'Interpreter','tex','FontSize',12);
        otherwise
            error('Unknown mode: %s', mode);
    end
end

function name = interactionTermName(a, b, coefNames)
    cand1 = [a ':' b];
    cand2 = [b ':' a];
    if any(strcmp(coefNames, cand1))
        name = cand1;
    elseif any(strcmp(coefNames, cand2))
        name = cand2;
    else
        name = cand1;
    end
end

function b = getCoef(coefTbl, termName)
    idx = strcmp(coefTbl.Name, termName);
    if ~any(idx)
        error('Term "%s" not found. Available: %s', termName, strjoin(coefTbl.Name', ', '));
    end
    b = coefTbl.Estimate(idx);
end

function p = getPval(coefTbl, termName)
    idx = strcmp(coefTbl.Name, termName);
    if ~any(idx)
        error('Term "%s" not found. Available: %s', termName, strjoin(coefTbl.Name', ', '));
    end
    p = coefTbl.pValue(idx);
end

function applyAgeColorbar(cmap, cbInfo)
    colormap(cmap);
    cb = colorbar;
    cb.Label.String = 'Age';
    if cbInfo.isNumeric
        cb.Ticks = [0 1];
        cb.TickLabels = {num2str(cbInfo.minVal), num2str(cbInfo.maxVal)};
    else
        cb.Ticks = linspace(0,1,numel(cbInfo.labels));
        cb.TickLabels = cbInfo.labels;
    end
end

function applydepthColorbar(cmap, cbInfo)
    colormap(cmap);
    cb = colorbar;
    cb.Label.String = 'Depth % from GW/WM boundary';
    if cbInfo.isNumeric
        cb.Ticks = [0 1];
        cb.TickLabels = {num2str(cbInfo.minVal), num2str(cbInfo.maxVal)};
    else
        cb.Ticks = linspace(0,1,numel(cbInfo.labels));
        cb.TickLabels = cbInfo.labels;
    end
end

function v = doubleifyAge(AgeVar)
% Convert AgeVar subset to numeric vector for averaging/coloring lines.
% If AgeVar is numeric -> return numeric.
% Else -> map categories to 1..K (order consistent within subset call).
    if isnumeric(AgeVar)
        v = double(AgeVar);
    else
        aCat = categorical(AgeVar);
        [~, ~, idx] = unique(aCat);
        v = double(idx);
    end
end

function c = ageToColor(ageVal, cmap, cbInfo)
% Map a scalar ageVal into an RGB row from cmap using cbInfo scaling
    nC = size(cmap,1);
    if cbInfo.isNumeric
        aMin = cbInfo.minVal; aMax = cbInfo.maxVal;
        if aMax == aMin
            cIdx = round(nC/2);
        else
            cIdx = 1 + round((nC-1) * (ageVal - aMin) / (aMax - aMin));
        end
    else
        % If categorical ages were mapped to 1..K, scale by cbInfo range
        aMin = cbInfo.minVal; aMax = cbInfo.maxVal;
        if aMax == aMin
            cIdx = round(nC/2);
        else
            cIdx = 1 + round((nC-1) * (ageVal - aMin) / (aMax - aMin));
        end
    end
    cIdx = max(1, min(nC, cIdx));
    c = cmap(cIdx, :);
end

function [cmap, ptColors, cbInfo] = makeAgeColors(AgeVar, nC)
    cmap = parula(nC);
    

    if isnumeric(AgeVar)
        ages = double(AgeVar);
        cbInfo.isNumeric = true;
        cbInfo.minVal = min(ages);
        cbInfo.maxVal = max(ages);
        cbInfo.labels = {};
    else
        aCat = categorical(AgeVar);
        [uAges, ~, idx] = unique(aCat);
        ages = double(idx);
        cbInfo.isNumeric = false;
        cbInfo.labels = cellstr(string(uAges));
        cbInfo.minVal = 1;
        cbInfo.maxVal = numel(uAges);
    end

    aMin = min(ages);
    aMax = max(ages);
    if aMax == aMin
        cIdx = repmat(round(nC/2), numel(ages), 1);
    else
        cIdx = 1 + round((nC-1) * (ages - aMin) / (aMax - aMin));
    end
    cIdx = max(1, min(nC, cIdx));
    ptColors = cmap(cIdx, :);
end


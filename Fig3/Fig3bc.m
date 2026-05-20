% R1 Analysis
% Linear Mixed-Effects Model: R1 ~ Region*log(Age_days) + (1|Subject)
% Full dataset and Infant subset (Age_days < 450)
% Plots shown in original Age_days scale
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('Fig3bc.csv');  % Replace with your actual filename

%% Create log-transformed age variable
data.Log_age = log(data.Age_days);

%% Display data summary
fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data));
fprintf('Number of regions: %d\n', length(unique(data.Region)));
fprintf('Number of unique subjects: %d\n', length(unique(data.Subject)));
fprintf('Age range: %.1f - %.1f days\n', min(data.Age_days), max(data.Age_days));
fprintf('Log(Age) range: %.3f - %.3f\n\n', min(data.Log_age), max(data.Log_age));

fprintf('Observations per region:\n');
disp(tabulate(data.Region));

%% Prepare variables
data.Region = categorical(data.Region);
data.Subject = categorical(data.Subject);

%% Fit Linear Mixed-Effects Model - Full Dataset
fprintf('\nFitting linear mixed-effects model (Full Dataset)...\n');
fprintf('Model formula: R1 ~ Region*log(Age_days) + (1|Subject)\n');
fprintf('Using REML estimation\n\n');

lme = fitlme(data, 'R1 ~ Region * Log_age + (1|Subject)', 'FitMethod', 'REML');

fprintf('Model Results:\n');
fprintf('==============\n\n');
disp(lme);

fprintf('\n=== Fixed Effects ===\n');
disp(lme.Coefficients);

fprintf('\n=== Random Effects ===\n');
[psi, mse] = covarianceParameters(lme);
subject_SD = sqrt(psi{1});
residual_SD = sqrt(mse);
ICC = psi{1} / (psi{1} + mse);

fprintf('Subject random intercept SD: %.4f\n', subject_SD);
fprintf('Residual SD: %.4f\n', residual_SD);
fprintf('Intraclass Correlation (ICC): %.4f\n', ICC);

fprintf('\n=== Model Fit Statistics ===\n');
fprintf('AIC: %.2f\n', lme.ModelCriterion.AIC);
fprintf('BIC: %.2f\n', lme.ModelCriterion.BIC);
fprintf('R-squared (ordinary): %.4f\n', lme.Rsquared.Ordinary);
fprintf('R-squared (adjusted): %.4f\n', lme.Rsquared.Adjusted);

fprintf('\n=== ANOVA for Fixed Effects ===\n');
anova_results = anova(lme);
disp(anova_results);

%% PLOT 1: Full Dataset - R1 vs Age_days by Region
fprintf('\nGenerating plot: R1 vs Age_days by Region (Full Dataset)...\n');

figure('Position', [100, 100, 1000, 600]);

% Define custom colors: V1=purple, mFus=pink, CoS=green
region_colors = containers.Map({'V1', 'mFus', 'CoS'}, ...
    {[0.6, 0.2, 0.8], [1, 0.4, 0.7], [0.2, 0.8, 0.4]});

regions_ordered = {'V1', 'CoS', 'mFus'};

% Get base coefficients
coef_names = lme.CoefficientNames;
coef_values = lme.Coefficients.Estimate;
intercept = coef_values(1);
log_age_effect = coef_values(strcmp(coef_names, 'Log_age'));

for i = 1:length(regions_ordered)
    region_name = regions_ordered{i};
    region_data = data(data.Region == region_name, :);
    
    % Remove any NaN values
    valid_idx = ~isnan(region_data.Age_days) & ~isnan(region_data.R1);
    region_data = region_data(valid_idx, :);
    
    if isempty(region_data)
        fprintf('Warning: No valid data for region %s\n', region_name);
        continue;
    end
    
    % Plot individual data points (in Age_days space)
    scatter(region_data.Age_days, region_data.R1, 50, ...
        region_colors(region_name), 'filled', ...
        'MarkerFaceAlpha', 0.3, ...
        'DisplayName', region_name);
    hold on;
    
    % Add regression line - create age range in Age_days, then transform to log
    age_min = min(region_data.Age_days);
    age_max = max(region_data.Age_days);
    age_range_days = linspace(age_min, age_max, 100)';
    age_range_log = log(age_range_days);  % Transform to log space for prediction
    
    % Calculate predictions based on region
    % Check which region is reference (the one NOT in coefficient names)
    has_V1_coef = any(strcmp(coef_names, 'Region_V1'));
    has_CoS_coef = any(strcmp(coef_names, 'Region_CoS'));
    has_mFus_coef = any(strcmp(coef_names, 'Region_mFus'));
    
    if strcmp(region_name, 'V1')
        if has_V1_coef
            % V1 is not reference
            region_intercept_idx = strcmp(coef_names, 'Region_V1');
            region_age_idx = strcmp(coef_names, 'Region_V1:Log_age') | strcmp(coef_names, 'Log_age:Region_V1');
            region_intercept = coef_values(region_intercept_idx);
            region_age_interaction = coef_values(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            predicted_R1 = (intercept + region_intercept) + (log_age_effect + region_age_interaction) .* age_range_log;
        else
            % V1 is reference
            predicted_R1 = intercept + log_age_effect .* age_range_log;
        end
        
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef
            % CoS is not reference
            region_intercept_idx = strcmp(coef_names, 'Region_CoS');
            region_age_idx = strcmp(coef_names, 'Region_CoS:Log_age') | strcmp(coef_names, 'Log_age:Region_CoS');
            region_intercept = coef_values(region_intercept_idx);
            region_age_interaction = coef_values(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            predicted_R1 = (intercept + region_intercept) + (log_age_effect + region_age_interaction) .* age_range_log;
        else
            % CoS is reference
            predicted_R1 = intercept + log_age_effect .* age_range_log;
        end
        
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef
            % mFus is not reference
            region_intercept_idx = strcmp(coef_names, 'Region_mFus');
            region_age_idx = strcmp(coef_names, 'Region_mFus:Log_age') | strcmp(coef_names, 'Log_age:Region_mFus');
            region_intercept = coef_values(region_intercept_idx);
            region_age_interaction = coef_values(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            predicted_R1 = (intercept + region_intercept) + (log_age_effect + region_age_interaction) .* age_range_log;
        else
            % mFus is reference
            predicted_R1 = intercept + log_age_effect .* age_range_log;
        end
    end
    
    % Plot regression line using Age_days on x-axis (NOT log)
    plot(age_range_days, predicted_R1, '-', ...
        'Color', region_colors(region_name), ...
        'LineWidth', 3, ...
        'HandleVisibility', 'off');
end

xlabel('Age (days)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('R1 (s^{-1})', 'FontSize', 14, 'FontWeight', 'bold');
title('R1 vs Age - Full Dataset', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

saveas(gcf, 'R1_vs_Age_full.png');
fprintf('Full dataset plot saved as "R1_vs_Age_full.png"\n');

%% Analyze infant subset (Age_days < 450)
fprintf('\n========================================\n');
fprintf('INFANT SUBSET ANALYSIS (Age_days < 450)\n');
fprintf('========================================\n\n');

infant_data = data(data.Age_days < 450, :);

% Drop unused categorical levels after subsetting
infant_data.Region = removecats(infant_data.Region);
infant_data.Subject = removecats(infant_data.Subject);

fprintf('Infant subset summary:\n');
fprintf('Total observations: %d\n', height(infant_data));
fprintf('Number of subjects: %d\n', length(unique(infant_data.Subject)));
fprintf('Age range: %.1f - %.1f days\n', min(infant_data.Age_days), max(infant_data.Age_days));
fprintf('Log(Age) range: %.3f - %.3f\n\n', min(infant_data.Log_age), max(infant_data.Log_age));

fprintf('Observations per region (infant):\n');
disp(tabulate(infant_data.Region));

fprintf('\nFitting model on infant subset...\n');
lme_infant = fitlme(infant_data, 'R1 ~ Region * Log_age + (1|Subject)', ...
    'FitMethod', 'REML');

fprintf('\nInfant Model Results:\n');
fprintf('=====================\n');
disp(lme_infant);

fprintf('\n=== Infant Fixed Effects ===\n');
disp(lme_infant.Coefficients);

fprintf('\n=== Infant Random Effects ===\n');
[psi_infant, mse_infant] = covarianceParameters(lme_infant);
subject_SD_infant = sqrt(psi_infant{1});
residual_SD_infant = sqrt(mse_infant);
ICC_infant = psi_infant{1} / (psi_infant{1} + mse_infant);

fprintf('Subject random intercept SD: %.4f\n', subject_SD_infant);
fprintf('Residual SD: %.4f\n', residual_SD_infant);
fprintf('ICC: %.4f\n', ICC_infant);

fprintf('\n=== Infant Model Fit Statistics ===\n');
fprintf('AIC: %.2f\n', lme_infant.ModelCriterion.AIC);
fprintf('BIC: %.2f\n', lme_infant.ModelCriterion.BIC);
fprintf('R-squared (ordinary): %.4f\n', lme_infant.Rsquared.Ordinary);
fprintf('R-squared (adjusted): %.4f\n', lme_infant.Rsquared.Adjusted);

fprintf('\n=== Infant ANOVA ===\n');
anova_infant = anova(lme_infant);
disp(anova_infant);

%% PLOT 2: Infant Dataset - R1 vs Age_days by Region
fprintf('\nGenerating plot: R1 vs Age_days by Region (Infant Dataset)...\n');

figure('Position', [100, 100, 1000, 600]);

infant_regions = categories(infant_data.Region);

% Get base coefficients for infant model
coef_names_infant = lme_infant.CoefficientNames;
coef_values_infant = lme_infant.Coefficients.Estimate;
intercept_infant = coef_values_infant(1);
log_age_effect_infant = coef_values_infant(strcmp(coef_names_infant, 'Log_age'));

for i = 1:length(infant_regions)
    region_name = char(infant_regions{i});
    region_data = infant_data(infant_data.Region == region_name, :);
    
    % Remove any NaN values
    valid_idx = ~isnan(region_data.Age_days) & ~isnan(region_data.R1);
    region_data = region_data(valid_idx, :);
    
    if isempty(region_data)
        fprintf('Warning: No valid data for region %s in infant subset\n', region_name);
        continue;
    end
    
    % Plot individual data points (in Age_days space)
    scatter(region_data.Age_days, region_data.R1, 50, ...
        region_colors(region_name), 'filled', ...
        'MarkerFaceAlpha', 0.3, ...
        'DisplayName', region_name);
    hold on;
    
    % Add regression line - create age range in Age_days, then transform to log
    age_min = min(region_data.Age_days);
    age_max = max(region_data.Age_days);
    age_range_days = linspace(age_min, age_max, 100)';
    age_range_log = log(age_range_days);  % Transform to log space for prediction
    
    % Calculate predictions based on region
    % Check which region is reference (the one NOT in coefficient names)
    has_V1_coef = any(strcmp(coef_names_infant, 'Region_V1'));
    has_CoS_coef = any(strcmp(coef_names_infant, 'Region_CoS'));
    has_mFus_coef = any(strcmp(coef_names_infant, 'Region_mFus'));
    
    if strcmp(region_name, 'V1')
        if has_V1_coef
            % V1 is not reference
            region_intercept_idx = strcmp(coef_names_infant, 'Region_V1');
            region_age_idx = strcmp(coef_names_infant, 'Region_V1:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_V1');
            region_intercept = coef_values_infant(region_intercept_idx);
            region_age_interaction = coef_values_infant(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            predicted_R1 = (intercept_infant + region_intercept) + (log_age_effect_infant + region_age_interaction) .* age_range_log;
        else
            % V1 is reference
            predicted_R1 = intercept_infant + log_age_effect_infant .* age_range_log;
        end
        
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef
            % CoS is not reference
            region_intercept_idx = strcmp(coef_names_infant, 'Region_CoS');
            region_age_idx = strcmp(coef_names_infant, 'Region_CoS:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_CoS');
            region_intercept = coef_values_infant(region_intercept_idx);
            region_age_interaction = coef_values_infant(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            predicted_R1 = (intercept_infant + region_intercept) + (log_age_effect_infant + region_age_interaction) .* age_range_log;
        else
            % CoS is reference
            predicted_R1 = intercept_infant + log_age_effect_infant .* age_range_log;
        end
        
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef
            % mFus is not reference
            region_intercept_idx = strcmp(coef_names_infant, 'Region_mFus');
            region_age_idx = strcmp(coef_names_infant, 'Region_mFus:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_mFus');
            region_intercept = coef_values_infant(region_intercept_idx);
            region_age_interaction = coef_values_infant(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            predicted_R1 = (intercept_infant + region_intercept) + (log_age_effect_infant + region_age_interaction) .* age_range_log;
        else
            % mFus is reference
            predicted_R1 = intercept_infant + log_age_effect_infant .* age_range_log;
        end
    end
    
    % Plot regression line using Age_days on x-axis (NOT log)
    plot(age_range_days, predicted_R1, '-', ...
        'Color', region_colors(region_name), ...
        'LineWidth', 3, ...
        'HandleVisibility', 'off');
end

xlabel('Age (days)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('R1 (s^{-1})', 'FontSize', 14, 'FontWeight', 'bold');
title('R1 vs Age - Infants (< 450 days)', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

saveas(gcf, 'R1_vs_Age_infant.png');
fprintf('Infant dataset plot saved as "R1_vs_Age_infant.png"\n');

%% Compare full vs infant models
fprintf('\n========================================\n');
fprintf('MODEL COMPARISON: Full vs Infant\n');
fprintf('========================================\n\n');

fprintf('%-25s %15s %15s\n', 'Metric', 'Full Dataset', 'Infant Only');
fprintf('%s\n', repmat('-', 1, 60));
fprintf('%-25s %15d %15d\n', 'N observations', height(data), height(infant_data));
fprintf('%-25s %15d %15d\n', 'N subjects', length(unique(data.Subject)), length(unique(infant_data.Subject)));
fprintf('%-25s %15.2f %15.2f\n', 'AIC', lme.ModelCriterion.AIC, lme_infant.ModelCriterion.AIC);
fprintf('%-25s %15.2f %15.2f\n', 'BIC', lme.ModelCriterion.BIC, lme_infant.ModelCriterion.BIC);
fprintf('%-25s %15.4f %15.4f\n', 'R-squared', lme.Rsquared.Ordinary, lme_infant.Rsquared.Ordinary);
fprintf('%-25s %15.4f %15.4f\n', 'ICC', ICC, ICC_infant);

fprintf('\n%-25s %15s %15s\n', 'Fixed Effect p-values', 'Full Dataset', 'Infant Only');
fprintf('%s\n', repmat('-', 1, 60));

age_idx_full = find(strcmp(anova_results.Term, 'Log_age'));
age_idx_infant = find(strcmp(anova_infant.Term, 'Log_age'));
fprintf('%-25s %15.6f %15.6f\n', 'Log_age', anova_results.pValue(age_idx_full), anova_infant.pValue(age_idx_infant));

region_idx_full = find(strcmp(anova_results.Term, 'Region'));
region_idx_infant = find(strcmp(anova_infant.Term, 'Region'));
fprintf('%-25s %15.6f %15.6f\n', 'Region', anova_results.pValue(region_idx_full), anova_infant.pValue(region_idx_infant));

int_idx_full = find(strcmp(anova_results.Term, 'Region:Log_age') | strcmp(anova_results.Term, 'Log_age:Region'));
int_idx_infant = find(strcmp(anova_infant.Term, 'Region:Log_age') | strcmp(anova_infant.Term, 'Log_age:Region'));
fprintf('%-25s %15.6f %15.6f\n', 'Region:Log_age', anova_results.pValue(int_idx_full), anova_infant.pValue(int_idx_infant));

%% Extract slopes for each region
fprintf('\n========================================\n');
fprintf('EXTRACTING SLOPES FOR EACH REGION\n');
fprintf('========================================\n\n');

fprintf('NOTE: Slopes are in log(Age) space\n');
fprintf('To interpret: A coefficient of β means that a 1-unit increase in log(Age)\n');
fprintf('corresponds to a β change in R1. Equivalently, doubling age (log(2)≈0.693)\n');
fprintf('corresponds to a β*0.693 change in R1.\n\n');

% Full dataset slopes
fprintf('FULL DATASET - Log(Age) slopes by region:\n');

% Determine reference category
has_V1_coef = any(strcmp(coef_names, 'Region_V1'));
has_CoS_coef = any(strcmp(coef_names, 'Region_CoS'));
has_mFus_coef = any(strcmp(coef_names, 'Region_mFus'));

base_log_age_slope = coef_values(strcmp(coef_names, 'Log_age'));

% V1 slope
if has_V1_coef
    V1_interaction = coef_values(strcmp(coef_names, 'Region_V1:Log_age') | strcmp(coef_names, 'Log_age:Region_V1'));
    if isempty(V1_interaction), V1_interaction = 0; end
    V1_slope_full = base_log_age_slope + V1_interaction;
else
    V1_slope_full = base_log_age_slope;  % V1 is reference
end
fprintf('  V1: %.6f s^{-1}/log(day)\n', V1_slope_full);

% CoS slope
if has_CoS_coef
    CoS_interaction = coef_values(strcmp(coef_names, 'Region_CoS:Log_age') | strcmp(coef_names, 'Log_age:Region_CoS'));
    if isempty(CoS_interaction), CoS_interaction = 0; end
    CoS_slope_full = base_log_age_slope + CoS_interaction;
else
    CoS_slope_full = base_log_age_slope;  % CoS is reference
end
fprintf('  CoS: %.6f s^{-1}/log(day)\n', CoS_slope_full);

% mFus slope
if has_mFus_coef
    mFus_interaction = coef_values(strcmp(coef_names, 'Region_mFus:Log_age') | strcmp(coef_names, 'Log_age:Region_mFus'));
    if isempty(mFus_interaction), mFus_interaction = 0; end
    mFus_slope_full = base_log_age_slope + mFus_interaction;
else
    mFus_slope_full = base_log_age_slope;  % mFus is reference
end
fprintf('  mFus: %.6f s^{-1}/log(day)\n', mFus_slope_full);

% Infant dataset slopes
fprintf('\nINFANT DATASET - Log(Age) slopes by region:\n');

% Determine reference category
has_V1_coef_infant = any(strcmp(coef_names_infant, 'Region_V1'));
has_CoS_coef_infant = any(strcmp(coef_names_infant, 'Region_CoS'));
has_mFus_coef_infant = any(strcmp(coef_names_infant, 'Region_mFus'));

base_log_age_slope_infant = coef_values_infant(strcmp(coef_names_infant, 'Log_age'));

% V1 slope
if has_V1_coef_infant
    V1_interaction_infant = coef_values_infant(strcmp(coef_names_infant, 'Region_V1:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_V1'));
    if isempty(V1_interaction_infant), V1_interaction_infant = 0; end
    V1_slope_infant = base_log_age_slope_infant + V1_interaction_infant;
else
    V1_slope_infant = base_log_age_slope_infant;  % V1 is reference
end
fprintf('  V1: %.6f s^{-1}/log(day)\n', V1_slope_infant);

% CoS slope
if has_CoS_coef_infant
    CoS_interaction_infant = coef_values_infant(strcmp(coef_names_infant, 'Region_CoS:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_CoS'));
    if isempty(CoS_interaction_infant), CoS_interaction_infant = 0; end
    CoS_slope_infant = base_log_age_slope_infant + CoS_interaction_infant;
else
    CoS_slope_infant = base_log_age_slope_infant;  % CoS is reference
end
fprintf('  CoS: %.6f s^{-1}/log(day)\n', CoS_slope_infant);

% mFus slope
if has_mFus_coef_infant
    mFus_interaction_infant = coef_values_infant(strcmp(coef_names_infant, 'Region_mFus:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_mFus'));
    if isempty(mFus_interaction_infant), mFus_interaction_infant = 0; end
    mFus_slope_infant = base_log_age_slope_infant + mFus_interaction_infant;
else
    mFus_slope_infant = base_log_age_slope_infant;  % mFus is reference
end
fprintf('  mFus: %.6f s^{-1}/log(day)\n', mFus_slope_infant);

%% Generate Supplemental Table
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLE\n');
fprintf('========================================\n\n');

% Build statistical test string - FULL DATASET
stat_test_str = sprintf('FULL DATASET (All ages, n=%d observations from %d subjects):\n', ...
    height(data), length(unique(data.Subject)));
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict R1 with ', ...
    'continuous log(Age_days) and Region (V1 vs. mFus vs. CoS), ', ...
    'with interaction, and with random variable of subject.\n\n'])];

% Add ANOVA results - Full dataset
age_idx = find(strcmp(anova_results.Term, 'Log_age'));
region_idx = find(strcmp(anova_results.Term, 'Region'));
interaction_idx = find(strcmp(anova_results.Term, 'Region:Log_age') | strcmp(anova_results.Term, 'Log_age:Region'));

stat_test_str = [stat_test_str, sprintf('Main effect of log(Age_days): F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_idx), anova_results.DF2(age_idx), ...
    anova_results.FStat(age_idx), anova_results.pValue(age_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_idx), anova_results.DF2(region_idx), ...
    anova_results.FStat(region_idx), anova_results.pValue(region_idx))];

stat_test_str = [stat_test_str, sprintf('Interaction effect between log(Age_days) and Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(interaction_idx), anova_results.DF2(interaction_idx), ...
    anova_results.FStat(interaction_idx), anova_results.pValue(interaction_idx))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f\n\n', lme.Rsquared.Ordinary)];

% Add infant-only model statistics
stat_test_str = [stat_test_str, sprintf('\nINFANT SUBSET (Age_days < 450, n=%d observations from %d subjects):\n', ...
    height(infant_data), length(unique(infant_data.Subject)))];
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict R1 with ', ...
    'continuous log(Age_days) and Region (V1 vs. mFus vs. CoS), ', ...
    'with interaction, and with random variable of subject.\n\n'])];

% Add ANOVA results - Infant dataset
age_idx_infant = find(strcmp(anova_infant.Term, 'Log_age'));
region_idx_infant = find(strcmp(anova_infant.Term, 'Region'));
interaction_idx_infant = find(strcmp(anova_infant.Term, 'Region:Log_age') | strcmp(anova_infant.Term, 'Log_age:Region'));

stat_test_str = [stat_test_str, sprintf('Main effect of log(Age_days): F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_infant.DF1(age_idx_infant), anova_infant.DF2(age_idx_infant), ...
    anova_infant.FStat(age_idx_infant), anova_infant.pValue(age_idx_infant))];

stat_test_str = [stat_test_str, sprintf('Main effect of Region: F(%d,%d)=%.2f, p=%.4f\n', ...
   anova_infant.DF1(region_idx_infant), anova_infant.DF2(region_idx_infant), ...
    anova_infant.FStat(region_idx_infant), anova_infant.pValue(region_idx_infant))];

stat_test_str = [stat_test_str, sprintf('Interaction effect between log(Age_days) and Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_infant.DF1(interaction_idx_infant), anova_infant.DF2(interaction_idx_infant), ...
    anova_infant.FStat(interaction_idx_infant), anova_infant.pValue(interaction_idx_infant))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f', lme_infant.Rsquared.Ordinary)];

% Create supplemental table structure
supp_table = table(...
    {'R1 Analysis'}, ...
    {'R1 (s^{-1}) as a function of log(Age_days) in V1, CoS, and mFus'}, ...
    {sprintf('See regression plots')}, ...
    {sprintf('Full dataset: n=%d observations from %d subjects\nInfant dataset: n=%d observations from %d subjects', ...
        height(data), length(unique(data.Subject)), ...
        height(infant_data), length(unique(infant_data.Subject)))}, ...
    {stat_test_str}, ...
    {sprintf('See model coefficients for region-specific log(age) slopes. Plots show predictions in original Age_days scale.')}, ...
    'VariableNames', {'Analysis', 'Measure', 'Values', 'N', 'Statistical_test', 'Notes'});

% Save to CSV
writetable(supp_table, 'R1_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "R1_Supplemental_Table.csv"\n');

% Also save a more readable text version
fid_supp = fopen('R1_Supplemental_Table.txt', 'w');
fprintf(fid_supp, '========================================================\n');
fprintf(fid_supp, 'SUPPLEMENTAL TABLE - R1 Analysis\n');
fprintf(fid_supp, '========================================================\n\n');

fprintf(fid_supp, 'Analysis: R1 vs log(Age_days) by Region\n');
fprintf(fid_supp, 'Note: Model fit on log-transformed age, plots show original age scale\n\n');

fprintf(fid_supp, 'Measure:\n');
fprintf(fid_supp, 'R1 (s^{-1}) as a function of log(Age_days) in V1, CoS, and mFus\n\n');

fprintf(fid_supp, 'Sample Sizes:\n');
fprintf(fid_supp, '-------------\n');
fprintf(fid_supp, 'Full dataset: n=%d observations from %d subjects\n', ...
    height(data), length(unique(data.Subject)));
fprintf(fid_supp, 'Infant dataset (Age_days < 450): n=%d observations from %d subjects\n\n', ...
    height(infant_data), length(unique(infant_data.Subject)));

fprintf(fid_supp, 'Statistical Tests:\n');
fprintf(fid_supp, '------------------\n');
fprintf(fid_supp, stat_test_str);

fprintf(fid_supp, '\n\n\nLog(Age) Slopes by Region:\n');
fprintf(fid_supp, '-------------------------\n');
fprintf(fid_supp, 'NOTE: Slopes are in log(Age) space\n');
fprintf(fid_supp, 'Interpretation: A coefficient of β means that a 1-unit increase in log(Age)\n');
fprintf(fid_supp, 'corresponds to a β change in R1. Equivalently, doubling age (log(2)≈0.693)\n');
fprintf(fid_supp, 'corresponds to a β*0.693 change in R1.\n\n');

fprintf(fid_supp, 'FULL DATASET:\n');
fprintf(fid_supp, '  V1: %.6f s^{-1}/log(day)\n', V1_slope_full);
fprintf(fid_supp, '  CoS: %.6f s^{-1}/log(day)\n', CoS_slope_full);
fprintf(fid_supp, '  mFus: %.6f s^{-1}/log(day)\n', mFus_slope_full);

fprintf(fid_supp, '\nINFANT DATASET:\n');
fprintf(fid_supp, '  V1: %.6f s^{-1}/log(day)\n', V1_slope_infant);
fprintf(fid_supp, '  CoS: %.6f s^{-1}/log(day)\n', CoS_slope_infant);
fprintf(fid_supp, '  mFus: %.6f s^{-1}/log(day)\n', mFus_slope_infant);

fprintf(fid_supp, '\n\nEffect of Age Doubling (multiply age by 2):\n');
fprintf(fid_supp, '-------------------------------------------\n');
fprintf(fid_supp, 'FULL DATASET:\n');
fprintf(fid_supp, '  V1: %.6f s^{-1} change per doubling of age\n', V1_slope_full * log(2));
fprintf(fid_supp, '  CoS: %.6f s^{-1} change per doubling of age\n', CoS_slope_full * log(2));
fprintf(fid_supp, '  mFus: %.6f s^{-1} change per doubling of age\n', mFus_slope_full * log(2));

fprintf(fid_supp, '\nINFANT DATASET:\n');
fprintf(fid_supp, '  V1: %.6f s^{-1} change per doubling of age\n', V1_slope_infant * log(2));
fprintf(fid_supp, '  CoS: %.6f s^{-1} change per doubling of age\n', CoS_slope_infant * log(2));
fprintf(fid_supp, '  mFus: %.6f s^{-1} change per doubling of age\n', mFus_slope_infant * log(2));

fprintf(fid_supp, '\n\n========================================================\n');
fclose(fid_supp);

fprintf('Readable supplemental table saved to "R1_Supplemental_Table.txt"\n');

% Display preview of statistics
fprintf('\n========================================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Statistical Tests\n');
fprintf('========================================================\n\n');
fprintf(stat_test_str);

fprintf('\n\n========================================================\n');
fprintf('INTERPRETATION GUIDE FOR LOG-TRANSFORMED AGE\n');
fprintf('========================================================\n\n');
fprintf('Your model uses log(Age_days) as the predictor.\n\n');
fprintf('Effect of Age Doubling (e.g., from 100 to 200 days):\n');
fprintf('-----------------------------------------------------\n');
fprintf('FULL DATASET:\n');
fprintf('  V1: %.6f s^{-1} change\n', V1_slope_full * log(2));
fprintf('  CoS: %.6f s^{-1} change\n', CoS_slope_full * log(2));
fprintf('  mFus: %.6f s^{-1} change\n', mFus_slope_full * log(2));
fprintf('\nINFANT DATASET:\n');
fprintf('  V1: %.6f s^{-1} change\n', V1_slope_infant * log(2));
fprintf('  CoS: %.6f s^{-1} change\n', CoS_slope_infant * log(2));
fprintf('  mFus: %.6f s^{-1} change\n', mFus_slope_infant * log(2));

fprintf('\n\n=== All outputs complete ===\n');
fprintf('Files generated:\n');
fprintf('  1. R1_vs_Age_full.png (plotted in Age_days, fit with log(Age))\n');
fprintf('  2. R1_vs_Age_infant.png (plotted in Age_days, fit with log(Age))\n');
fprintf('  3. R1_Supplemental_Table.csv\n');
fprintf('  4. R1_Supplemental_Table.txt\n\n');

fprintf('=== ANALYSIS COMPLETE ===\n\n');

%% Generate Supplemental Figure with 3 Panels
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL FIGURE\n');
fprintf('========================================\n\n');

% Create figure with 3 panels
fig_supp = figure('Position', [100, 100, 1800, 500]);

%% PANEL A: Infant data with Log_age on x-axis and confidence intervals
subplot(1, 3, 1);

infant_regions = {'V1', 'CoS', 'mFus'};

for i = 1:length(infant_regions)
    region_name = infant_regions{i};
    region_data = infant_data(infant_data.Region == region_name, :);
    
    % Remove any NaN values
    valid_idx = ~isnan(region_data.Log_age) & ~isnan(region_data.R1);
    region_data = region_data(valid_idx, :);
    
    if isempty(region_data)
        continue;
    end
    
    % Plot individual data points
    scatter(region_data.Log_age, region_data.R1, 50, ...
        region_colors(region_name), 'filled', ...
        'MarkerFaceAlpha', 0.3, ...
        'DisplayName', region_name);
    hold on;
    
    % Create log_age range for predictions
    log_age_min = min(region_data.Log_age);
    log_age_max = max(region_data.Log_age);
    log_age_range = linspace(log_age_min, log_age_max, 100)';
    
    % Calculate predictions manually (population-level, no random effects)
    % Check which region is reference
    has_V1_coef = any(strcmp(coef_names_infant, 'Region_V1'));
    has_CoS_coef = any(strcmp(coef_names_infant, 'Region_CoS'));
    has_mFus_coef = any(strcmp(coef_names_infant, 'Region_mFus'));
    
    if strcmp(region_name, 'V1')
        if has_V1_coef
            % V1 is not reference
            region_intercept_idx = strcmp(coef_names_infant, 'Region_V1');
            region_age_idx = strcmp(coef_names_infant, 'Region_V1:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_V1');
            region_intercept = coef_values_infant(region_intercept_idx);
            region_age_interaction = coef_values_infant(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            pred_R1 = (intercept_infant + region_intercept) + (log_age_effect_infant + region_age_interaction) .* log_age_range;
        else
            % V1 is reference
            pred_R1 = intercept_infant + log_age_effect_infant .* log_age_range;
        end
        
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef
            % CoS is not reference
            region_intercept_idx = strcmp(coef_names_infant, 'Region_CoS');
            region_age_idx = strcmp(coef_names_infant, 'Region_CoS:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_CoS');
            region_intercept = coef_values_infant(region_intercept_idx);
            region_age_interaction = coef_values_infant(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            pred_R1 = (intercept_infant + region_intercept) + (log_age_effect_infant + region_age_interaction) .* log_age_range;
        else
            % CoS is reference
            pred_R1 = intercept_infant + log_age_effect_infant .* log_age_range;
        end
        
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef
            % mFus is not reference
            region_intercept_idx = strcmp(coef_names_infant, 'Region_mFus');
            region_age_idx = strcmp(coef_names_infant, 'Region_mFus:Log_age') | strcmp(coef_names_infant, 'Log_age:Region_mFus');
            region_intercept = coef_values_infant(region_intercept_idx);
            region_age_interaction = coef_values_infant(region_age_idx);
            if isempty(region_intercept), region_intercept = 0; end
            if isempty(region_age_interaction), region_age_interaction = 0; end
            pred_R1 = (intercept_infant + region_intercept) + (log_age_effect_infant + region_age_interaction) .* log_age_range;
        else
            % mFus is reference
            pred_R1 = intercept_infant + log_age_effect_infant .* log_age_range;
        end
    end
    
    % Calculate confidence intervals manually
    % Get design matrix for fixed effects
    n_pred = length(log_age_range);
    
    % Build design matrix based on region
    if strcmp(region_name, 'V1')
        if has_V1_coef
            X = [ones(n_pred,1), log_age_range, ones(n_pred,1), zeros(n_pred,1), log_age_range, zeros(n_pred,1)];
        else
            % V1 is reference
            X = [ones(n_pred,1), log_age_range, zeros(n_pred,1), zeros(n_pred,1), zeros(n_pred,1), zeros(n_pred,1)];
        end
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef
            X = [ones(n_pred,1), log_age_range, zeros(n_pred,1), ones(n_pred,1), zeros(n_pred,1), log_age_range];
        else
            % CoS is reference
            X = [ones(n_pred,1), log_age_range, zeros(n_pred,1), zeros(n_pred,1), zeros(n_pred,1), zeros(n_pred,1)];
        end
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef
            X = [ones(n_pred,1), log_age_range, ones(n_pred,1), zeros(n_pred,1), log_age_range, zeros(n_pred,1)];
        else
            % mFus is reference
            X = [ones(n_pred,1), log_age_range, zeros(n_pred,1), zeros(n_pred,1), zeros(n_pred,1), zeros(n_pred,1)];
        end
    end
    
    % Get covariance matrix of fixed effects
    coef_cov = lme_infant.CoefficientCovariance;
    
    % Calculate standard errors of predictions
    pred_var = sum((X * coef_cov) .* X, 2);
    pred_se = sqrt(pred_var);
    
    % 95% confidence intervals
    alpha = 0.05;
    tcrit = tinv(1-alpha/2, lme_infant.DFE);
    pred_CI_lower = pred_R1 - tcrit * pred_se;
    pred_CI_upper = pred_R1 + tcrit * pred_se;
    
    % Plot confidence interval as shaded area
    fill([log_age_range; flipud(log_age_range)], ...
         [pred_CI_lower; flipud(pred_CI_upper)], ...
         region_colors(region_name), ...
         'FaceAlpha', 0.2, ...
         'EdgeColor', 'none', ...
         'HandleVisibility', 'off');
    
    % Plot regression line
    plot(log_age_range, pred_R1, '-', ...
        'Color', region_colors(region_name), ...
        'LineWidth', 3, ...
        'HandleVisibility', 'off');
end

xlabel('log(Age) [log(days)]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('R1 (s^{-1})', 'FontSize', 12, 'FontWeight', 'bold');
title('A) Infant Data: R1 vs log(Age)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
box on;
set(gca, 'FontSize', 10);

%% PANEL B: Intercepts at Age_days = 0 (extrapolated)
subplot(1, 3, 2);

% Extract intercepts and standard errors for each region
% Note: Age_days = 0 means Log_age = -Inf, so we'll use the model intercept
% which represents the value when Log_age = 0 (i.e., Age_days = 1)

intercepts = zeros(3, 1);
intercept_SE = zeros(3, 1);

% Get coefficient table
coef_table = lme_infant.Coefficients;

% Base intercept (reference region)
base_intercept = coef_table.Estimate(strcmp(lme_infant.CoefficientNames, '(Intercept)'));
base_intercept_SE = coef_table.SE(strcmp(lme_infant.CoefficientNames, '(Intercept)'));

% Determine which region is reference
has_V1_coef = any(strcmp(lme_infant.CoefficientNames, 'Region_V1'));
has_CoS_coef = any(strcmp(lme_infant.CoefficientNames, 'Region_CoS'));
has_mFus_coef = any(strcmp(lme_infant.CoefficientNames, 'Region_mFus'));

region_order = {'V1', 'CoS', 'mFus'};
for i = 1:3
    region_name = region_order{i};
    
    if strcmp(region_name, 'V1')
        if has_V1_coef
            region_coef_idx = strcmp(lme_infant.CoefficientNames, 'Region_V1');
            intercepts(i) = base_intercept + coef_table.Estimate(region_coef_idx);
            intercept_SE(i) = sqrt(base_intercept_SE^2 + coef_table.SE(region_coef_idx)^2);
        else
            % V1 is reference
            intercepts(i) = base_intercept;
            intercept_SE(i) = base_intercept_SE;
        end
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef
            region_coef_idx = strcmp(lme_infant.CoefficientNames, 'Region_CoS');
            intercepts(i) = base_intercept + coef_table.Estimate(region_coef_idx);
            intercept_SE(i) = sqrt(base_intercept_SE^2 + coef_table.SE(region_coef_idx)^2);
        else
            % CoS is reference
            intercepts(i) = base_intercept;
            intercept_SE(i) = base_intercept_SE;
        end
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef
            region_coef_idx = strcmp(lme_infant.CoefficientNames, 'Region_mFus');
            intercepts(i) = base_intercept + coef_table.Estimate(region_coef_idx);
            intercept_SE(i) = sqrt(base_intercept_SE^2 + coef_table.SE(region_coef_idx)^2);
        else
            % mFus is reference
            intercepts(i) = base_intercept;
            intercept_SE(i) = base_intercept_SE;
        end
    end
end

% Plot intercepts with error bars (SEM)
x_pos = 1:3;
for i = 1:3
    % Plot error bar
    errorbar(x_pos(i), intercepts(i), intercept_SE(i), ...
        'o', 'MarkerSize', 10, 'MarkerFaceColor', region_colors(region_order{i}), ...
        'MarkerEdgeColor', region_colors(region_order{i}), ...
        'Color', region_colors(region_order{i}), ...
        'LineWidth', 2, 'CapSize', 10);
    hold on;
end

xlim([0.5 3.5]);
set(gca, 'XTick', 1:3, 'XTickLabel', region_order);
ylabel('Intercept: R1 at log(Age)=0 (s^{-1})', 'FontSize', 12, 'FontWeight', 'bold');
title('B) Model Intercepts by Region', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
box on;
set(gca, 'FontSize', 10);

%% PANEL C: Slopes (log-age effects) for each region
subplot(1, 3, 3);

% Extract slopes and standard errors for each region
slopes = zeros(3, 1);
slope_SE = zeros(3, 1);

% Base slope (reference region)
base_slope = coef_table.Estimate(strcmp(lme_infant.CoefficientNames, 'Log_age'));
base_slope_SE = coef_table.SE(strcmp(lme_infant.CoefficientNames, 'Log_age'));

for i = 1:3
    region_name = region_order{i};
    
    if strcmp(region_name, 'V1')
        if has_V1_coef
            interaction_idx = strcmp(lme_infant.CoefficientNames, 'Region_V1:Log_age') | ...
                            strcmp(lme_infant.CoefficientNames, 'Log_age:Region_V1');
            if any(interaction_idx)
                slopes(i) = base_slope + coef_table.Estimate(interaction_idx);
                slope_SE(i) = sqrt(base_slope_SE^2 + coef_table.SE(interaction_idx)^2);
            else
                slopes(i) = base_slope;
                slope_SE(i) = base_slope_SE;
            end
        else
            % V1 is reference
            slopes(i) = base_slope;
            slope_SE(i) = base_slope_SE;
        end
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef
            interaction_idx = strcmp(lme_infant.CoefficientNames, 'Region_CoS:Log_age') | ...
                            strcmp(lme_infant.CoefficientNames, 'Log_age:Region_CoS');
            if any(interaction_idx)
                slopes(i) = base_slope + coef_table.Estimate(interaction_idx);
                slope_SE(i) = sqrt(base_slope_SE^2 + coef_table.SE(interaction_idx)^2);
            else
                slopes(i) = base_slope;
                slope_SE(i) = base_slope_SE;
            end
        else
            % CoS is reference
            slopes(i) = base_slope;
            slope_SE(i) = base_slope_SE;
        end
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef
            interaction_idx = strcmp(lme_infant.CoefficientNames, 'Region_mFus:Log_age') | ...
                            strcmp(lme_infant.CoefficientNames, 'Log_age:Region_mFus');
            if any(interaction_idx)
                slopes(i) = base_slope + coef_table.Estimate(interaction_idx);
                slope_SE(i) = sqrt(base_slope_SE^2 + coef_table.SE(interaction_idx)^2);
            else
                slopes(i) = base_slope;
                slope_SE(i) = base_slope_SE;
            end
        else
            % mFus is reference
            slopes(i) = base_slope;
            slope_SE(i) = base_slope_SE;
        end
    end
end

% Plot slopes with error bars (SEM)
x_pos = 1:3;
for i = 1:3
    % Plot error bar
    errorbar(x_pos(i), slopes(i), slope_SE(i), ...
        'o', 'MarkerSize', 10, 'MarkerFaceColor', region_colors(region_order{i}), ...
        'MarkerEdgeColor', region_colors(region_order{i}), ...
        'Color', region_colors(region_order{i}), ...
        'LineWidth', 2, 'CapSize', 10);
    hold on;
end

xlim([0.5 3.5]);
set(gca, 'XTick', 1:3, 'XTickLabel', region_order);
ylabel('Slope: ΔR1/Δlog(Age) (s^{-1}/log(day))', 'FontSize', 12, 'FontWeight', 'bold');
title('C) Age Effect (Slopes) by Region', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
box on;
set(gca, 'FontSize', 10);

% Save the supplemental figure
saveas(fig_supp, 'FigS10abc.png');
fprintf('\nSupplemental figure saved as "FigS10abc.png"\n');

% Also save as higher resolution
saveas(fig_supp, 'FigS10abc.tif');
fprintf('Supplemental figure (high-res) saved as "FigS10abc.tif"\n');

%% Print summary of panel B and C values
fprintf('\n========================================\n');
fprintf('SUPPLEMENTAL FIGURE - PANELS B & C VALUES\n');
fprintf('========================================\n\n');

fprintf('Panel B - Intercepts (R1 at log(Age)=0, i.e., Age=1 day):\n');
fprintf('----------------------------------------------------------\n');
for i = 1:3
    fprintf('  %s: %.4f ± %.4f s^{-1} (mean ± SEM)\n', ...
        region_order{i}, intercepts(i), intercept_SE(i));
end

fprintf('\nPanel C - Slopes (effect of log(Age)):\n');
fprintf('---------------------------------------\n');
for i = 1:3
    fprintf('  %s: %.4f ± %.4f s^{-1}/log(day) (mean ± SEM)\n', ...
        region_order{i}, slopes(i), slope_SE(i));
end

fprintf('\nInterpretation of Slopes (effect of doubling age):\n');
fprintf('---------------------------------------------------\n');
for i = 1:3
    fprintf('  %s: %.4f s^{-1} per doubling of age\n', ...
        region_order{i}, slopes(i) * log(2));
end

fprintf('\n=== SUPPLEMENTAL FIGURE COMPLETE ===\n\n');

%% Statistical Comparisons - Uncorrected t-tests with Cohen's d
fprintf('\n========================================\n');
fprintf('STATISTICAL COMPARISONS (Uncorrected)\n');
fprintf('========================================\n\n');

fprintf('Note: Using uncorrected t-tests for planned pairwise comparisons.\n');
fprintf('Effect sizes (Cohen''s d) provided for interpretation.\n\n');

%% Compare Intercepts between regions
fprintf('INTERCEPT COMPARISONS:\n');
fprintf('======================\n\n');

region_order = {'V1', 'CoS', 'mFus'};
idx_v1 = 1;
idx_cos = 2;
idx_mfus = 3;

% Use residual SD for effect size calculation
residual_sd = sqrt(mse_infant);

% V1 vs CoS
diff_V1_CoS = intercepts(idx_v1) - intercepts(idx_cos);
se_V1_CoS = sqrt(intercept_SE(idx_v1)^2 + intercept_SE(idx_cos)^2);
t_V1_CoS = diff_V1_CoS / se_V1_CoS;
df_intercept = lme_infant.DFE;
p_V1_CoS = 2 * (1 - tcdf(abs(t_V1_CoS), df_intercept));
d_V1_CoS = diff_V1_CoS / residual_sd;

fprintf('V1 vs CoS:\n');
fprintf('  Difference: %.4f s^{-1}\n', diff_V1_CoS);
fprintf('  SE: %.4f\n', se_V1_CoS);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_intercept, t_V1_CoS, p_V1_CoS);
fprintf('  Cohen''s d = %.3f\n', d_V1_CoS);
if p_V1_CoS < 0.001
    fprintf('  ***\n\n');
elseif p_V1_CoS < 0.01
    fprintf('  **\n\n');
elseif p_V1_CoS < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% V1 vs mFus
diff_V1_mFus = intercepts(idx_v1) - intercepts(idx_mfus);
se_V1_mFus = sqrt(intercept_SE(idx_v1)^2 + intercept_SE(idx_mfus)^2);
t_V1_mFus = diff_V1_mFus / se_V1_mFus;
p_V1_mFus = 2 * (1 - tcdf(abs(t_V1_mFus), df_intercept));
d_V1_mFus = diff_V1_mFus / residual_sd;

fprintf('V1 vs mFus:\n');
fprintf('  Difference: %.4f s^{-1}\n', diff_V1_mFus);
fprintf('  SE: %.4f\n', se_V1_mFus);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_intercept, t_V1_mFus, p_V1_mFus);
fprintf('  Cohen''s d = %.3f\n', d_V1_mFus);
if p_V1_mFus < 0.001
    fprintf('  ***\n\n');
elseif p_V1_mFus < 0.01
    fprintf('  **\n\n');
elseif p_V1_mFus < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% CoS vs mFus
diff_CoS_mFus = intercepts(idx_cos) - intercepts(idx_mfus);
se_CoS_mFus = sqrt(intercept_SE(idx_cos)^2 + intercept_SE(idx_mfus)^2);
t_CoS_mFus = diff_CoS_mFus / se_CoS_mFus;
p_CoS_mFus = 2 * (1 - tcdf(abs(t_CoS_mFus), df_intercept));
d_CoS_mFus = diff_CoS_mFus / residual_sd;

fprintf('CoS vs mFus:\n');
fprintf('  Difference: %.4f s^{-1}\n', diff_CoS_mFus);
fprintf('  SE: %.4f\n', se_CoS_mFus);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_intercept, t_CoS_mFus, p_CoS_mFus);
fprintf('  Cohen''s d = %.3f\n', d_CoS_mFus);
if p_CoS_mFus < 0.001
    fprintf('  ***\n\n');
elseif p_CoS_mFus < 0.01
    fprintf('  **\n\n');
elseif p_CoS_mFus < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

%% Compare Slopes between regions
fprintf('SLOPE COMPARISONS:\n');
fprintf('==================\n\n');

df_slope = lme_infant.DFE;

% V1 vs CoS
diff_V1_CoS_slope = slopes(idx_v1) - slopes(idx_cos);
se_V1_CoS_slope = sqrt(slope_SE(idx_v1)^2 + slope_SE(idx_cos)^2);
t_V1_CoS_slope = diff_V1_CoS_slope / se_V1_CoS_slope;
p_V1_CoS_slope = 2 * (1 - tcdf(abs(t_V1_CoS_slope), df_slope));
d_V1_CoS_slope = diff_V1_CoS_slope / residual_sd;

fprintf('V1 vs CoS:\n');
fprintf('  Difference: %.6f s^{-1}/log(day)\n', diff_V1_CoS_slope);
fprintf('  SE: %.6f\n', se_V1_CoS_slope);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_slope, t_V1_CoS_slope, p_V1_CoS_slope);
fprintf('  Cohen''s d = %.3f\n', d_V1_CoS_slope);
if p_V1_CoS_slope < 0.001
    fprintf('  ***\n\n');
elseif p_V1_CoS_slope < 0.01
    fprintf('  **\n\n');
elseif p_V1_CoS_slope < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% V1 vs mFus
diff_V1_mFus_slope = slopes(idx_v1) - slopes(idx_mfus);
se_V1_mFus_slope = sqrt(slope_SE(idx_v1)^2 + slope_SE(idx_mfus)^2);
t_V1_mFus_slope = diff_V1_mFus_slope / se_V1_mFus_slope;
p_V1_mFus_slope = 2 * (1 - tcdf(abs(t_V1_mFus_slope), df_slope));
d_V1_mFus_slope = diff_V1_mFus_slope / residual_sd;

fprintf('V1 vs mFus:\n');
fprintf('  Difference: %.6f s^{-1}/log(day)\n', diff_V1_mFus_slope);
fprintf('  SE: %.6f\n', se_V1_mFus_slope);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_slope, t_V1_mFus_slope, p_V1_mFus_slope);
fprintf('  Cohen''s d = %.3f\n', d_V1_mFus_slope);
if p_V1_mFus_slope < 0.001
    fprintf('  ***\n\n');
elseif p_V1_mFus_slope < 0.01
    fprintf('  **\n\n');
elseif p_V1_mFus_slope < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% CoS vs mFus
diff_CoS_mFus_slope = slopes(idx_cos) - slopes(idx_mfus);
se_CoS_mFus_slope = sqrt(slope_SE(idx_cos)^2 + slope_SE(idx_mfus)^2);
t_CoS_mFus_slope = diff_CoS_mFus_slope / se_CoS_mFus_slope;
p_CoS_mFus_slope = 2 * (1 - tcdf(abs(t_CoS_mFus_slope), df_slope));
d_CoS_mFus_slope = diff_CoS_mFus_slope / residual_sd;

fprintf('CoS vs mFus:\n');
fprintf('  Difference: %.6f s^{-1}/log(day)\n', diff_CoS_mFus_slope);
fprintf('  SE: %.6f\n', se_CoS_mFus_slope);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_slope, t_CoS_mFus_slope, p_CoS_mFus_slope);
fprintf('  Cohen''s d = %.3f\n', d_CoS_mFus_slope);
if p_CoS_mFus_slope < 0.001
    fprintf('  ***\n\n');
elseif p_CoS_mFus_slope < 0.01
    fprintf('  **\n\n');
elseif p_CoS_mFus_slope < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

%% Summary Table
fprintf('========================================\n');
fprintf('SUMMARY TABLE\n');
fprintf('========================================\n\n');

fprintf('INTERCEPTS (R1 at Age=1 day):\n');
fprintf('%-15s %12s %8s %8s %10s %10s\n', 'Comparison', 'Difference', 'SE', 't', 'p', 'Cohen''s d');
fprintf('%s\n', repmat('-', 1, 75));
fprintf('%-15s %12.4f %8.4f %8.3f %10.4f %10.3f', 'V1 vs CoS', diff_V1_CoS, se_V1_CoS, t_V1_CoS, p_V1_CoS, d_V1_CoS);
if p_V1_CoS < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.4f %8.4f %8.3f %10.4f %10.3f', 'V1 vs mFus', diff_V1_mFus, se_V1_mFus, t_V1_mFus, p_V1_mFus, d_V1_mFus);
if p_V1_mFus < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.4f %8.4f %8.3f %10.4f %10.3f', 'CoS vs mFus', diff_CoS_mFus, se_CoS_mFus, t_CoS_mFus, p_CoS_mFus, d_CoS_mFus);
if p_CoS_mFus < 0.05, fprintf(' *'); end
fprintf('\n\n');

fprintf('SLOPES (developmental rate):\n');
fprintf('%-15s %12s %8s %8s %10s %10s\n', 'Comparison', 'Difference', 'SE', 't', 'p', 'Cohen''s d');
fprintf('%s\n', repmat('-', 1, 75));
fprintf('%-15s %12.6f %8.6f %8.3f %10.4f %10.3f', 'V1 vs CoS', diff_V1_CoS_slope, se_V1_CoS_slope, t_V1_CoS_slope, p_V1_CoS_slope, d_V1_CoS_slope);
if p_V1_CoS_slope < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.6f %8.6f %8.3f %10.4f %10.3f', 'V1 vs mFus', diff_V1_mFus_slope, se_V1_mFus_slope, t_V1_mFus_slope, p_V1_mFus_slope, d_V1_mFus_slope);
if p_V1_mFus_slope < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.6f %8.6f %8.3f %10.4f %10.3f', 'CoS vs mFus', diff_CoS_mFus_slope, se_CoS_mFus_slope, t_CoS_mFus_slope, p_CoS_mFus_slope, d_CoS_mFus_slope);
if p_CoS_mFus_slope < 0.05, fprintf(' *'); end
fprintf('\n\n');

fprintf('Effect size interpretation:\n');
fprintf('  |d| < 0.2: negligible\n');
fprintf('  |d| ≈ 0.2: small\n');
fprintf('  |d| ≈ 0.5: medium\n');
fprintf('  |d| ≈ 0.8: large\n');
fprintf('  |d| > 1.2: very large\n\n');

%% Save results
comparison_table = table(...
    {'V1 vs CoS'; 'V1 vs mFus'; 'CoS vs mFus'; 'V1 vs CoS'; 'V1 vs mFus'; 'CoS vs mFus'}, ...
    {'Intercept'; 'Intercept'; 'Intercept'; 'Slope'; 'Slope'; 'Slope'}, ...
    [diff_V1_CoS; diff_V1_mFus; diff_CoS_mFus; diff_V1_CoS_slope; diff_V1_mFus_slope; diff_CoS_mFus_slope], ...
    [se_V1_CoS; se_V1_mFus; se_CoS_mFus; se_V1_CoS_slope; se_V1_mFus_slope; se_CoS_mFus_slope], ...
    [t_V1_CoS; t_V1_mFus; t_CoS_mFus; t_V1_CoS_slope; t_V1_mFus_slope; t_CoS_mFus_slope], ...
    [p_V1_CoS; p_V1_mFus; p_CoS_mFus; p_V1_CoS_slope; p_V1_mFus_slope; p_CoS_mFus_slope], ...
    [d_V1_CoS; d_V1_mFus; d_CoS_mFus; d_V1_CoS_slope; d_V1_mFus_slope; d_CoS_mFus_slope], ...
    'VariableNames', {'Comparison', 'Parameter', 'Difference', 'SE', 't_value', 'p_value', 'Cohens_d'});

writetable(comparison_table, 'R1_Infants_Slope_Intercept.csv');
fprintf('Pairwise comparisons saved to "R1_Infants_Slope_Intercept.csv"\n');

fprintf('\n=== STATISTICAL COMPARISONS COMPLETE ===\n\n');

%% Statistical Comparisons for FULL DATASET (All Ages)
fprintf('\n========================================\n');
fprintf('FULL DATASET COMPARISONS (All Ages)\n');
fprintf('========================================\n\n');

fprintf('Note: Using uncorrected t-tests for planned pairwise comparisons.\n');
fprintf('Effect sizes (Cohen''s d) provided for interpretation.\n\n');

%% Extract intercepts and slopes for full dataset
fprintf('Extracting parameters from full dataset model...\n\n');

% Get coefficient table for full model
coef_table_full = lme.Coefficients;
coef_names_list_full = lme.CoefficientNames;

% Base intercept and slope (reference region)
base_intercept_full = coef_table_full.Estimate(strcmp(coef_names_list_full, '(Intercept)'));
base_intercept_SE_full = coef_table_full.SE(strcmp(coef_names_list_full, '(Intercept)'));
base_slope_full = coef_table_full.Estimate(strcmp(coef_names_list_full, 'Log_age'));
base_slope_SE_full = coef_table_full.SE(strcmp(coef_names_list_full, 'Log_age'));

% Determine reference category for full dataset
has_V1_coef_full = any(strcmp(coef_names_list_full, 'Region_V1'));
has_CoS_coef_full = any(strcmp(coef_names_list_full, 'Region_CoS'));
has_mFus_coef_full = any(strcmp(coef_names_list_full, 'Region_mFus'));

if ~has_V1_coef_full
    ref_region_full = 'V1';
elseif ~has_CoS_coef_full
    ref_region_full = 'CoS';
elseif ~has_mFus_coef_full
    ref_region_full = 'mFus';
end

fprintf('Reference region: %s\n\n', ref_region_full);

% Calculate intercepts for each region
intercepts_full = zeros(3, 1);
intercept_SE_full = zeros(3, 1);

region_order = {'V1', 'CoS', 'mFus'};
for i = 1:3
    region_name = region_order{i};
    
    if strcmp(region_name, 'V1')
        if has_V1_coef_full
            region_coef_idx = strcmp(coef_names_list_full, 'Region_V1');
            intercepts_full(i) = base_intercept_full + coef_table_full.Estimate(region_coef_idx);
            intercept_SE_full(i) = sqrt(base_intercept_SE_full^2 + coef_table_full.SE(region_coef_idx)^2);
        else
            intercepts_full(i) = base_intercept_full;
            intercept_SE_full(i) = base_intercept_SE_full;
        end
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef_full
            region_coef_idx = strcmp(coef_names_list_full, 'Region_CoS');
            intercepts_full(i) = base_intercept_full + coef_table_full.Estimate(region_coef_idx);
            intercept_SE_full(i) = sqrt(base_intercept_SE_full^2 + coef_table_full.SE(region_coef_idx)^2);
        else
            intercepts_full(i) = base_intercept_full;
            intercept_SE_full(i) = base_intercept_SE_full;
        end
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef_full
            region_coef_idx = strcmp(coef_names_list_full, 'Region_mFus');
            intercepts_full(i) = base_intercept_full + coef_table_full.Estimate(region_coef_idx);
            intercept_SE_full(i) = sqrt(base_intercept_SE_full^2 + coef_table_full.SE(region_coef_idx)^2);
        else
            intercepts_full(i) = base_intercept_full;
            intercept_SE_full(i) = base_intercept_SE_full;
        end
    end
end

% Calculate slopes for each region
slopes_full = zeros(3, 1);
slope_SE_full = zeros(3, 1);

for i = 1:3
    region_name = region_order{i};
    
    if strcmp(region_name, 'V1')
        if has_V1_coef_full
            interaction_idx = strcmp(coef_names_list_full, 'Region_V1:Log_age') | ...
                            strcmp(coef_names_list_full, 'Log_age:Region_V1');
            if any(interaction_idx)
                slopes_full(i) = base_slope_full + coef_table_full.Estimate(interaction_idx);
                slope_SE_full(i) = sqrt(base_slope_SE_full^2 + coef_table_full.SE(interaction_idx)^2);
            else
                slopes_full(i) = base_slope_full;
                slope_SE_full(i) = base_slope_SE_full;
            end
        else
            slopes_full(i) = base_slope_full;
            slope_SE_full(i) = base_slope_SE_full;
        end
    elseif strcmp(region_name, 'CoS')
        if has_CoS_coef_full
            interaction_idx = strcmp(coef_names_list_full, 'Region_CoS:Log_age') | ...
                            strcmp(coef_names_list_full, 'Log_age:Region_CoS');
            if any(interaction_idx)
                slopes_full(i) = base_slope_full + coef_table_full.Estimate(interaction_idx);
                slope_SE_full(i) = sqrt(base_slope_SE_full^2 + coef_table_full.SE(interaction_idx)^2);
            else
                slopes_full(i) = base_slope_full;
                slope_SE_full(i) = base_slope_SE_full;
            end
        else
            slopes_full(i) = base_slope_full;
            slope_SE_full(i) = base_slope_SE_full;
        end
    elseif strcmp(region_name, 'mFus')
        if has_mFus_coef_full
            interaction_idx = strcmp(coef_names_list_full, 'Region_mFus:Log_age') | ...
                            strcmp(coef_names_list_full, 'Log_age:Region_mFus');
            if any(interaction_idx)
                slopes_full(i) = base_slope_full + coef_table_full.Estimate(interaction_idx);
                slope_SE_full(i) = sqrt(base_slope_SE_full^2 + coef_table_full.SE(interaction_idx)^2);
            else
                slopes_full(i) = base_slope_full;
                slope_SE_full(i) = base_slope_SE_full;
            end
        else
            slopes_full(i) = base_slope_full;
            slope_SE_full(i) = base_slope_SE_full;
        end
    end
end

fprintf('Intercepts (R1 at log(Age)=0):\n');
for i = 1:3
    fprintf('  %s: %.4f ± %.4f s^{-1}\n', region_order{i}, intercepts_full(i), intercept_SE_full(i));
end

fprintf('\nSlopes:\n');
for i = 1:3
    fprintf('  %s: %.6f ± %.6f s^{-1}/log(day)\n', region_order{i}, slopes_full(i), slope_SE_full(i));
end
fprintf('\n');

%% Compare Intercepts - Full Dataset
fprintf('INTERCEPT COMPARISONS (Full Dataset):\n');
fprintf('======================================\n\n');

idx_v1 = 1;
idx_cos = 2;
idx_mfus = 3;

% Use residual SD for effect size calculation
residual_sd_full = sqrt(mse);
df_full = lme.DFE;

% V1 vs CoS
diff_V1_CoS_full = intercepts_full(idx_v1) - intercepts_full(idx_cos);
se_V1_CoS_full = sqrt(intercept_SE_full(idx_v1)^2 + intercept_SE_full(idx_cos)^2);
t_V1_CoS_full = diff_V1_CoS_full / se_V1_CoS_full;
p_V1_CoS_full = 2 * (1 - tcdf(abs(t_V1_CoS_full), df_full));
d_V1_CoS_full = diff_V1_CoS_full / residual_sd_full;

fprintf('V1 vs CoS:\n');
fprintf('  Difference: %.4f s^{-1}\n', diff_V1_CoS_full);
fprintf('  SE: %.4f\n', se_V1_CoS_full);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_full, t_V1_CoS_full, p_V1_CoS_full);
fprintf('  Cohen''s d = %.3f\n', d_V1_CoS_full);
if p_V1_CoS_full < 0.001
    fprintf('  ***\n\n');
elseif p_V1_CoS_full < 0.01
    fprintf('  **\n\n');
elseif p_V1_CoS_full < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% V1 vs mFus
diff_V1_mFus_full = intercepts_full(idx_v1) - intercepts_full(idx_mfus);
se_V1_mFus_full = sqrt(intercept_SE_full(idx_v1)^2 + intercept_SE_full(idx_mfus)^2);
t_V1_mFus_full = diff_V1_mFus_full / se_V1_mFus_full;
p_V1_mFus_full = 2 * (1 - tcdf(abs(t_V1_mFus_full), df_full));
d_V1_mFus_full = diff_V1_mFus_full / residual_sd_full;

fprintf('V1 vs mFus:\n');
fprintf('  Difference: %.4f s^{-1}\n', diff_V1_mFus_full);
fprintf('  SE: %.4f\n', se_V1_mFus_full);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_full, t_V1_mFus_full, p_V1_mFus_full);
fprintf('  Cohen''s d = %.3f\n', d_V1_mFus_full);
if p_V1_mFus_full < 0.001
    fprintf('  ***\n\n');
elseif p_V1_mFus_full < 0.01
    fprintf('  **\n\n');
elseif p_V1_mFus_full < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% CoS vs mFus
diff_CoS_mFus_full = intercepts_full(idx_cos) - intercepts_full(idx_mfus);
se_CoS_mFus_full = sqrt(intercept_SE_full(idx_cos)^2 + intercept_SE_full(idx_mfus)^2);
t_CoS_mFus_full = diff_CoS_mFus_full / se_CoS_mFus_full;
p_CoS_mFus_full = 2 * (1 - tcdf(abs(t_CoS_mFus_full), df_full));
d_CoS_mFus_full = diff_CoS_mFus_full / residual_sd_full;

fprintf('CoS vs mFus:\n');
fprintf('  Difference: %.4f s^{-1}\n', diff_CoS_mFus_full);
fprintf('  SE: %.4f\n', se_CoS_mFus_full);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_full, t_CoS_mFus_full, p_CoS_mFus_full);
fprintf('  Cohen''s d = %.3f\n', d_CoS_mFus_full);
if p_CoS_mFus_full < 0.001
    fprintf('  ***\n\n');
elseif p_CoS_mFus_full < 0.01
    fprintf('  **\n\n');
elseif p_CoS_mFus_full < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

%% Compare Slopes - Full Dataset
fprintf('SLOPE COMPARISONS (Full Dataset):\n');
fprintf('==================================\n\n');

% V1 vs CoS
diff_V1_CoS_slope_full = slopes_full(idx_v1) - slopes_full(idx_cos);
se_V1_CoS_slope_full = sqrt(slope_SE_full(idx_v1)^2 + slope_SE_full(idx_cos)^2);
t_V1_CoS_slope_full = diff_V1_CoS_slope_full / se_V1_CoS_slope_full;
p_V1_CoS_slope_full = 2 * (1 - tcdf(abs(t_V1_CoS_slope_full), df_full));
d_V1_CoS_slope_full = diff_V1_CoS_slope_full / residual_sd_full;

fprintf('V1 vs CoS:\n');
fprintf('  Difference: %.6f s^{-1}/log(day)\n', diff_V1_CoS_slope_full);
fprintf('  SE: %.6f\n', se_V1_CoS_slope_full);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_full, t_V1_CoS_slope_full, p_V1_CoS_slope_full);
fprintf('  Cohen''s d = %.3f\n', d_V1_CoS_slope_full);
if p_V1_CoS_slope_full < 0.001
    fprintf('  ***\n\n');
elseif p_V1_CoS_slope_full < 0.01
    fprintf('  **\n\n');
elseif p_V1_CoS_slope_full < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% V1 vs mFus
diff_V1_mFus_slope_full = slopes_full(idx_v1) - slopes_full(idx_mfus);
se_V1_mFus_slope_full = sqrt(slope_SE_full(idx_v1)^2 + slope_SE_full(idx_mfus)^2);
t_V1_mFus_slope_full = diff_V1_mFus_slope_full / se_V1_mFus_slope_full;
p_V1_mFus_slope_full = 2 * (1 - tcdf(abs(t_V1_mFus_slope_full), df_full));
d_V1_mFus_slope_full = diff_V1_mFus_slope_full / residual_sd_full;

fprintf('V1 vs mFus:\n');
fprintf('  Difference: %.6f s^{-1}/log(day)\n', diff_V1_mFus_slope_full);
fprintf('  SE: %.6f\n', se_V1_mFus_slope_full);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_full, t_V1_mFus_slope_full, p_V1_mFus_slope_full);
fprintf('  Cohen''s d = %.3f\n', d_V1_mFus_slope_full);
if p_V1_mFus_slope_full < 0.001
    fprintf('  ***\n\n');
elseif p_V1_mFus_slope_full < 0.01
    fprintf('  **\n\n');
elseif p_V1_mFus_slope_full < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

% CoS vs mFus
diff_CoS_mFus_slope_full = slopes_full(idx_cos) - slopes_full(idx_mfus);
se_CoS_mFus_slope_full = sqrt(slope_SE_full(idx_cos)^2 + slope_SE_full(idx_mfus)^2);
t_CoS_mFus_slope_full = diff_CoS_mFus_slope_full / se_CoS_mFus_slope_full;
p_CoS_mFus_slope_full = 2 * (1 - tcdf(abs(t_CoS_mFus_slope_full), df_full));
d_CoS_mFus_slope_full = diff_CoS_mFus_slope_full / residual_sd_full;

fprintf('CoS vs mFus:\n');
fprintf('  Difference: %.6f s^{-1}/log(day)\n', diff_CoS_mFus_slope_full);
fprintf('  SE: %.6f\n', se_CoS_mFus_slope_full);
fprintf('  t(%d) = %.3f, p = %.4f\n', df_full, t_CoS_mFus_slope_full, p_CoS_mFus_slope_full);
fprintf('  Cohen''s d = %.3f\n', d_CoS_mFus_slope_full);
if p_CoS_mFus_slope_full < 0.001
    fprintf('  ***\n\n');
elseif p_CoS_mFus_slope_full < 0.01
    fprintf('  **\n\n');
elseif p_CoS_mFus_slope_full < 0.05
    fprintf('  *\n\n');
else
    fprintf('  ns\n\n');
end

%% Summary Table - Full Dataset
fprintf('========================================\n');
fprintf('SUMMARY TABLE (Full Dataset)\n');
fprintf('========================================\n\n');

fprintf('INTERCEPTS (R1 at Age=1 day):\n');
fprintf('%-15s %12s %8s %8s %10s %10s\n', 'Comparison', 'Difference', 'SE', 't', 'p', 'Cohen''s d');
fprintf('%s\n', repmat('-', 1, 75));
fprintf('%-15s %12.4f %8.4f %8.3f %10.4f %10.3f', 'V1 vs CoS', diff_V1_CoS_full, se_V1_CoS_full, t_V1_CoS_full, p_V1_CoS_full, d_V1_CoS_full);
if p_V1_CoS_full < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.4f %8.4f %8.3f %10.4f %10.3f', 'V1 vs mFus', diff_V1_mFus_full, se_V1_mFus_full, t_V1_mFus_full, p_V1_mFus_full, d_V1_mFus_full);
if p_V1_mFus_full < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.4f %8.4f %8.3f %10.4f %10.3f', 'CoS vs mFus', diff_CoS_mFus_full, se_CoS_mFus_full, t_CoS_mFus_full, p_CoS_mFus_full, d_CoS_mFus_full);
if p_CoS_mFus_full < 0.05, fprintf(' *'); end
fprintf('\n\n');

fprintf('SLOPES (developmental rate):\n');
fprintf('%-15s %12s %8s %8s %10s %10s\n', 'Comparison', 'Difference', 'SE', 't', 'p', 'Cohen''s d');
fprintf('%s\n', repmat('-', 1, 75));
fprintf('%-15s %12.6f %8.6f %8.3f %10.4f %10.3f', 'V1 vs CoS', diff_V1_CoS_slope_full, se_V1_CoS_slope_full, t_V1_CoS_slope_full, p_V1_CoS_slope_full, d_V1_CoS_slope_full);
if p_V1_CoS_slope_full < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.6f %8.6f %8.3f %10.4f %10.3f', 'V1 vs mFus', diff_V1_mFus_slope_full, se_V1_mFus_slope_full, t_V1_mFus_slope_full, p_V1_mFus_slope_full, d_V1_mFus_slope_full);
if p_V1_mFus_slope_full < 0.05, fprintf(' *'); end
fprintf('\n');
fprintf('%-15s %12.6f %8.6f %8.3f %10.4f %10.3f', 'CoS vs mFus', diff_CoS_mFus_slope_full, se_CoS_mFus_slope_full, t_CoS_mFus_slope_full, p_CoS_mFus_slope_full, d_CoS_mFus_slope_full);
if p_CoS_mFus_slope_full < 0.05, fprintf(' *'); end
fprintf('\n\n');

fprintf('Effect size interpretation:\n');
fprintf('  |d| < 0.2: negligible\n');
fprintf('  |d| ≈ 0.2: small\n');
fprintf('  |d| ≈ 0.5: medium\n');
fprintf('  |d| ≈ 0.8: large\n');
fprintf('  |d| > 1.2: very large\n\n');

%% Save results - Full Dataset
comparison_table_full = table(...
    {'V1 vs CoS'; 'V1 vs mFus'; 'CoS vs mFus'; 'V1 vs CoS'; 'V1 vs mFus'; 'CoS vs mFus'}, ...
    {'Intercept'; 'Intercept'; 'Intercept'; 'Slope'; 'Slope'; 'Slope'}, ...
    [diff_V1_CoS_full; diff_V1_mFus_full; diff_CoS_mFus_full; diff_V1_CoS_slope_full; diff_V1_mFus_slope_full; diff_CoS_mFus_slope_full], ...
    [se_V1_CoS_full; se_V1_mFus_full; se_CoS_mFus_full; se_V1_CoS_slope_full; se_V1_mFus_slope_full; se_CoS_mFus_slope_full], ...
    [t_V1_CoS_full; t_V1_mFus_full; t_CoS_mFus_full; t_V1_CoS_slope_full; t_V1_mFus_slope_full; t_CoS_mFus_slope_full], ...
    [p_V1_CoS_full; p_V1_mFus_full; p_CoS_mFus_full; p_V1_CoS_slope_full; p_V1_mFus_slope_full; p_CoS_mFus_slope_full], ...
    [d_V1_CoS_full; d_V1_mFus_full; d_CoS_mFus_full; d_V1_CoS_slope_full; d_V1_mFus_slope_full; d_CoS_mFus_slope_full], ...
    'VariableNames', {'Comparison', 'Parameter', 'Difference', 'SE', 't_value', 'p_value', 'Cohens_d'});

writetable(comparison_table_full, 'R1_Lifespan_Slope_Intercept.csv');
fprintf('Full dataset pairwise comparisons saved to "R1_Lifespan_Slope_Intercept.csv"\n');

%% Comparison of Infant vs Full Dataset Results
fprintf('\n========================================\n');
fprintf('COMPARISON: INFANT vs FULL DATASET\n');
fprintf('========================================\n\n');

fprintf('INTERCEPT COMPARISONS:\n');
fprintf('%-20s %15s %15s\n', 'Comparison', 'Infant (p)', 'Full (p)');
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-20s %15.4f %15.4f\n', 'V1 vs CoS', p_V1_CoS, p_V1_CoS_full);
fprintf('%-20s %15.4f %15.4f\n', 'V1 vs mFus', p_V1_mFus, p_V1_mFus_full);
fprintf('%-20s %15.4f %15.4f\n', 'CoS vs mFus', p_CoS_mFus, p_CoS_mFus_full);

fprintf('\nSLOPE COMPARISONS:\n');
fprintf('%-20s %15s %15s\n', 'Comparison', 'Infant (p)', 'Full (p)');
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-20s %15.4f %15.4f\n', 'V1 vs CoS', p_V1_CoS_slope, p_V1_CoS_slope_full);
fprintf('%-20s %15.4f %15.4f\n', 'V1 vs mFus', p_V1_mFus_slope, p_V1_mFus_slope_full);
fprintf('%-20s %15.4f %15.4f\n', 'CoS vs mFus', p_CoS_mFus_slope, p_CoS_mFus_slope_full);

fprintf('\nEFFECT SIZES (Cohen''s d):\n');
fprintf('%-20s %15s %15s\n', 'Intercept Comparison', 'Infant (d)', 'Full (d)');
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-20s %15.3f %15.3f\n', 'V1 vs CoS', d_V1_CoS, d_V1_CoS_full);
fprintf('%-20s %15.3f %15.3f\n', 'V1 vs mFus', d_V1_mFus, d_V1_mFus_full);
fprintf('%-20s %15.3f %15.3f\n', 'CoS vs mFus', d_CoS_mFus, d_CoS_mFus_full);

fprintf('\n%-20s %15s %15s\n', 'Slope Comparison', 'Infant (d)', 'Full (d)');
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-20s %15.3f %15.3f\n', 'V1 vs CoS', d_V1_CoS_slope, d_V1_CoS_slope_full);
fprintf('%-20s %15.3f %15.3f\n', 'V1 vs mFus', d_V1_mFus_slope, d_V1_mFus_slope_full);
fprintf('%-20s %15.3f %15.3f\n', 'CoS vs mFus', d_CoS_mFus_slope, d_CoS_mFus_slope_full);

fprintf('\n=== FULL DATASET STATISTICAL COMPARISONS COMPLETE ===\n\n');

fprintf('\n=== ALL ANALYSES COMPLETE ===\n');
fprintf('\nFinal output files:\n');
fprintf('  1. R1_vs_Age_full.png - Full dataset plot\n');
fprintf('  2. R1_vs_Age_infant.png - Infant dataset plot\n');
fprintf('  3. R1_Supplemental_Table.csv - Statistical summary table\n');
fprintf('  4. R1_Supplemental_Table.txt - Readable statistical summary\n');
fprintf('  5. FigS10abc.png - Supplemental figure (3 panels)\n');
fprintf('  6. FigS10abc.tif - High-resolution supplemental figure\n');
fprintf('  7. R1_Infants_Slope_Intercept.csv - Infant pairwise comparisons\n');
fprintf('  8. R1_Lifespan_Slope_Intercept.csv - Full dataset pairwise comparisons\n');
fprintf('\n');
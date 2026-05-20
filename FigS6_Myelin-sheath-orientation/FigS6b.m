% Average Angle Analysis
% Linear Mixed-Effects Model: Average_angle ~ Layer*Region + (1|Slide_number)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data_angle = readtable('FigS6b.csv');  % Replace with your actual filename

%% Display data summary
fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data_angle));
fprintf('Number of Layer: %d\n', length(unique(data_angle.Layer)));
fprintf('Number of regions: %d\n', length(unique(data_angle.Region)));
fprintf('Number of unique slides: %d\n', length(unique(data_angle.Slide_number)));

fprintf('\nLayer:\n');
disp(unique(data_angle.Layer));

fprintf('Regions:\n');
disp(unique(data_angle.Region));

fprintf('\nObservations per Layer:\n');
disp(tabulate(data_angle.Layer));

fprintf('\nObservations per region:\n');
disp(tabulate(data_angle.Region));

%% Prepare variables
data_angle.Layer = categorical(data_angle.Layer);
data_angle.Region = categorical(data_angle.Region);
data_angle.Slide_number = categorical(data_angle.Slide_number);

%% Fit Linear Mixed-Effects Model
fprintf('\n\nFitting linear mixed-effects model...\n');
fprintf('Model formula: Average_angle ~ Layer*Region + (1|Slide_number)\n');
fprintf('Using REML estimation\n\n');

lme_angle = fitlme(data_angle, 'Average_angle ~ Layer * Region + (1|Slide_number)', 'FitMethod', 'REML');

%% Check coefficient names
fprintf('\n=== Checking Coefficient Names ===\n');
fprintf('Available coefficient names:\n');
for i = 1:length(lme_angle.CoefficientNames)
    fprintf('  %d: %s\n', i, lme_angle.CoefficientNames{i});
end
fprintf('\n');

fprintf('Model Results:\n');
fprintf('==============\n\n');
disp(lme_angle);

fprintf('\n=== Fixed Effects ===\n');
disp(lme_angle.Coefficients);

fprintf('\n=== Random Effects ===\n');
[psi_angle, mse_angle] = covarianceParameters(lme_angle);
slide_SD = sqrt(psi_angle{1});
residual_SD = sqrt(mse_angle);
ICC_angle = psi_angle{1} / (psi_angle{1} + mse_angle);

fprintf('Slide random intercept SD: %.4f\n', slide_SD);
fprintf('Residual SD: %.4f\n', residual_SD);
fprintf('Intraclass Correlation (ICC): %.4f\n', ICC_angle);

fprintf('\n=== Model Fit Statistics ===\n');
fprintf('AIC: %.2f\n', lme_angle.ModelCriterion.AIC);
fprintf('BIC: %.2f\n', lme_angle.ModelCriterion.BIC);
fprintf('R-squared (ordinary): %.4f\n', lme_angle.Rsquared.Ordinary);
fprintf('R-squared (adjusted): %.4f\n', lme_angle.Rsquared.Adjusted);

fprintf('\n=== ANOVA for Fixed Effects ===\n');
anova_results_angle = anova(lme_angle);
disp(anova_results_angle);

%% Create visualization - Average Angle by Layer and Region
% Load the histogram data
data = readtable('FigS6b_histogram.csv');

% Display data structure
disp('Data structure:');
disp(head(data));
disp('Column names:');
disp(data.Properties.VariableNames);

% Get unique values
unique_regions = unique(data.Region);
unique_Layer = unique(data.Layer);
unique_ages = unique(data.Age);

fprintf('\nUnique Regions: %d\n', length(unique_regions));
fprintf('Unique Layer: %d\n', length(unique_Layer));
fprintf('Unique Ages: %d\n', length(unique_ages));

%% Perform post-hoc pairwise comparisons
fprintf('\n========================================\n');
fprintf('POST-HOC PAIRWISE COMPARISONS\n');
fprintf('========================================\n\n');

posthoc_results = {};

% PART 1: Layer comparisons within each region (for interaction effect)
fprintf('\nLayer comparisons within each region:\n');
for i = 1:length(unique_regions)
    current_region = unique_regions{i};
    
    % Get data for this region
    region_subset = data_angle(data_angle.Region == current_region, :);
    
    % Compare all layer pairs within this region
    for j = 1:length(unique_Layer)-1
        for k = j+1:length(unique_Layer)
            layer1 = unique_Layer{j};
            layer2 = unique_Layer{k};
            
            data1 = region_subset(region_subset.Layer == layer1, :);
            data2 = region_subset(region_subset.Layer == layer2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.Average_angle, data2.Average_angle);
                
                comparison = sprintf('%s, %s vs. %s, %s', char(layer1), char(current_region), char(layer2), char(current_region));
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
end

% PART 2: Region comparisons within each layer (for interaction effect)
fprintf('\nRegion comparisons within each layer:\n');
for i = 1:length(unique_Layer)
    current_Layer = unique_Layer{i};
    
    % Get data for this layer
    layer_subset = data_angle(data_angle.Layer == current_Layer, :);
    
    % Compare all region pairs within this layer
    for j = 1:length(unique_regions)-1
        for k = j+1:length(unique_regions)
            region1 = unique_regions{j};
            region2 = unique_regions{k};
            
            data1 = layer_subset(layer_subset.Region == region1, :);
            data2 = layer_subset(layer_subset.Region == region2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.Average_angle, data2.Average_angle);
                
                comparison = sprintf('%s, %s vs. %s, %s', char(region1), char(current_Layer), char(region2), char(current_Layer));
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
end

% PART 3: Overall layer comparisons (collapsed across regions)
fprintf('\nOverall layer comparisons (collapsed across regions):\n');
for j = 1:length(unique_Layer)-1
    for k = j+1:length(unique_Layer)
        layer1 = unique_Layer{j};
        layer2 = unique_Layer{k};
        
        data1 = data_angle(data_angle.Layer == layer1, :);
        data2 = data_angle(data_angle.Layer == layer2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Average_angle, data2.Average_angle);
            
            comparison = sprintf('%s vs. %s (all regions)', char(layer1), char(layer2));
            
            fprintf('  %s: p=%.6f', comparison, p);
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                elseif p < 0.01
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                else
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
end

% PART 4: Overall region comparisons (collapsed across layers)
fprintf('\nOverall region comparisons (collapsed across layers):\n');
for j = 1:length(unique_regions)-1
    for k = j+1:length(unique_regions)
        region1 = unique_regions{j};
        region2 = unique_regions{k};
        
        data1 = data_angle(data_angle.Region == region1, :);
        data2 = data_angle(data_angle.Region == region2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Average_angle, data2.Average_angle);
            
            comparison = sprintf('%s vs. %s (all layers)', char(region1), char(region2));
            
            fprintf('  %s: p=%.6f', comparison, p);
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                elseif p < 0.01
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                else
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
end

% Build significance string for table
significance_str = 'Post-hoc pairwise comparisons using Student''s t-test:\n\n';
if ~isempty(posthoc_results)
    for i = 1:length(posthoc_results)
        significance_str = [significance_str, posthoc_results{i}, '\n'];
    end
    significance_str = [significance_str, '\nAll other comparisons p>0.05'];
else
    significance_str = [significance_str, 'No significant pairwise comparisons (all p>0.05)'];
end

%% Generate Supplemental Table
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLE\n');
fprintf('========================================\n\n');

% Build the Values string (mean ± SEM for each combination)
values_str = '';
for i = 1:length(unique_regions)
    values_str = [values_str, char(unique_regions{i}), ':\n'];
    
    for j = 1:length(unique_Layer)
        subset = data_angle(data_angle.Region == unique_regions{i} & data_angle.Layer == unique_Layer{j}, :);
        
        if ~isempty(subset)
            mean_val = mean(subset.Average_angle);
            sem_val = std(subset.Average_angle) / sqrt(height(subset));
            values_str = [values_str, sprintf('  %s: %.2f±%.2f degrees\n', char(unique_Layer{j}), mean_val, sem_val)];
        end
    end
end

% Build N string
n_str = sprintf('Total: %d observations from %d slides\n', height(data_angle), length(unique(data_angle.Slide_number)));
n_str = [n_str, sprintf('Layers: %d (%s)\n', length(unique_Layer), strjoin(cellstr(unique_Layer), ', '))];
n_str = [n_str, sprintf('Regions: %d (%s)', length(unique_regions), strjoin(cellstr(unique_regions), ', '))];

% Build statistical test string
stat_test_str_angle = sprintf('AVERAGE ANGLE ANALYSIS (n=%d observations from %d slides):\n', ...
    height(data_angle), length(unique(data_angle.Slide_number)));
stat_test_str_angle = [stat_test_str_angle, sprintf(['Restricted Maximum Likelihood model (REML) to predict Average_angle with ', ...
    'Layer and Region, with interaction, and with random variable of Slide_number.\n\n'])];

% Add ANOVA results
Layer_idx = find(strcmp(anova_results_angle.Term, 'Layer'));
region_idx = find(strcmp(anova_results_angle.Term, 'Region'));
interaction_idx = find(strcmp(anova_results_angle.Term, 'Layer:Region') | strcmp(anova_results_angle.Term, 'Region:Layer'));

stat_test_str_angle = [stat_test_str_angle, sprintf('Main effect of Layer: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_angle.DF1(Layer_idx), anova_results_angle.DF2(Layer_idx), ...
    anova_results_angle.FStat(Layer_idx), anova_results_angle.pValue(Layer_idx))];

stat_test_str_angle = [stat_test_str_angle, sprintf('Main effect of Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_angle.DF1(region_idx), anova_results_angle.DF2(region_idx), ...
    anova_results_angle.FStat(region_idx), anova_results_angle.pValue(region_idx))];

stat_test_str_angle = [stat_test_str_angle, sprintf('Interaction effect between Layer and Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_angle.DF1(interaction_idx), anova_results_angle.DF2(interaction_idx), ...
    anova_results_angle.FStat(interaction_idx), anova_results_angle.pValue(interaction_idx))];

stat_test_str_angle = [stat_test_str_angle, sprintf('R²=%.2f', lme_angle.Rsquared.Ordinary)];

% Create supplemental table with post-hoc results
supp_table_angle = table(...
    {'Fig. S6b'}, ...
    {'Average Angle (degrees) of myelin fibers by Layer and Region'}, ...
    {values_str}, ...
    {n_str}, ...
    {stat_test_str_angle}, ...
    {significance_str}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table_angle, 'Average_Angle_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "Average_Angle_Supplemental_Table.csv"\n');

% Save readable text version
fid_supp_angle = fopen('Average_Angle_Supplemental_Table.txt', 'w');
fprintf(fid_supp_angle, '========================================================\n');
fprintf(fid_supp_angle, 'SUPPLEMENTAL TABLE - Average Angle Analysis\n');
fprintf(fid_supp_angle, '========================================================\n\n');

fprintf(fid_supp_angle, 'Figure: Fig. S6b\n\n');

fprintf(fid_supp_angle, 'Measure:\n');
fprintf(fid_supp_angle, 'Average Angle (degrees) of myelin fibers by Layer and Region\n\n');

fprintf(fid_supp_angle, 'Values (Mean±SEM):\n');
fprintf(fid_supp_angle, '------------------\n');
fprintf(fid_supp_angle, values_str);

fprintf(fid_supp_angle, '\n\nSample Sizes:\n');
fprintf(fid_supp_angle, '-------------\n');
fprintf(fid_supp_angle, n_str);

fprintf(fid_supp_angle, '\n\n\nStatistical Tests:\n');
fprintf(fid_supp_angle, '------------------\n');
fprintf(fid_supp_angle, stat_test_str_angle);

fprintf(fid_supp_angle, '\n\n\nPost-hoc Comparisons:\n');
fprintf(fid_supp_angle, '---------------------\n');
fprintf(fid_supp_angle, significance_str);

fprintf(fid_supp_angle, '\n\n========================================================\n');
fclose(fid_supp_angle);

fprintf('Readable supplemental table saved to "Average_Angle_Supplemental_Table.txt"\n');

% Display preview of statistics
fprintf('\n========================================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Statistical Tests\n');
fprintf('========================================================\n\n');
fprintf(stat_test_str_angle);

fprintf('\n========================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Post-hoc Comparisons\n');
fprintf('========================================\n\n');
fprintf(significance_str);
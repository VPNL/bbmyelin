% BCAS1 density_mm2 Analysis - Region and Age Group (categorical)
% Linear Mixed-Effects Model: BCAS1_density_mm2 ~ Region*Age_group + (1|Slide_number)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('Fig2f.csv');

%% Display data summary
fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data));
fprintf('Number of regions: %d\n', length(unique(data.Region)));
fprintf('Number of unique slides: %d\n', length(unique(data.Slide_number)));
fprintf('Age range: %.1f - %.1f months\n\n', min(data.Age), max(data.Age));

fprintf('Observations per region:\n');
disp(tabulate(data.Region));

fprintf('Observations per age group:\n');
disp(tabulate(data.Age_group));

%% Prepare variables
data.Region = categorical(data.Region);
data.Slide_number = categorical(data.Slide_number);
data.Age_group = categorical(data.Age_group);

%% Fit Linear Mixed-Effects Model
fprintf('\nFitting linear mixed-effects model...\n');
fprintf('Model formula: BCAS1_density_mm2 ~ Region*Age_group + (1|Slide_number)\n');
fprintf('Using REML estimation\n\n');

lme = fitlme(data, 'BCAS1_density_mm2 ~ Region * Age_group + (1|Slide_number)', 'FitMethod', 'REML');

fprintf('Model Results:\n');
fprintf('==============\n\n');
disp(lme);

fprintf('\n=== Fixed Effects ===\n');
disp(lme.Coefficients);

fprintf('\n=== Random Effects ===\n');
[psi, mse] = covarianceParameters(lme);
slide_SD = sqrt(psi{1});
residual_SD = sqrt(mse);
ICC = psi{1} / (psi{1} + mse);

fprintf('Slide_number random intercept SD: %.4f\n', slide_SD);
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

%% Get unique categories
age_groups = categories(data.Age_group);
regions_ordered = {'Calc', 'CoS', 'FG'};

% Define custom colors: Calc=purple, FG=pink, CoS=green
region_colors = containers.Map({'Calc', 'FG', 'CoS'}, ...
                               {[0.6, 0.2, 0.8], [1, 0.4, 0.7], [0.2, 0.8, 0.4]});

%% PLOT: Regions by Age Group
fprintf('\nGenerating plot: Regions across age groups...\n');

figure('Position', [100, 100, 1000, 600]);

n_groups = length(age_groups);

for i = 1:length(regions_ordered)
    region_name = regions_ordered{i};
    region_data = data(data.Region == region_name, :);
    
    means = zeros(n_groups, 1);
    sems = zeros(n_groups, 1);
    x_positions = 1:n_groups;
    
    for j = 1:n_groups
        group_data = region_data(region_data.Age_group == age_groups{j}, :);
        if ~isempty(group_data)
            means(j) = mean(group_data.BCAS1_density_mm2);
            sems(j) = std(group_data.BCAS1_density_mm2) / sqrt(height(group_data));
        else
            means(j) = NaN;
            sems(j) = NaN;
        end
    end
    
    errorbar(x_positions, means, sems, 'o', ...
             'Color', region_colors(region_name), ...
             'MarkerFaceColor', region_colors(region_name), ...
             'MarkerSize', 10, ...
             'LineWidth', 2, ...
             'CapSize', 8, ...
             'DisplayName', region_name);
    hold on;
end

set(gca, 'XTick', 1:n_groups, 'XTickLabel', age_groups);
xtickangle(45);
xlabel('Age Group', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('BCAS1 density (cells/mm^2)', 'FontSize', 14, 'FontWeight', 'bold');
title('BCAS1 Density Across Regions and Age Groups', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

filename = 'BCAS1_density_by_region_age.png';
saveas(gcf, filename);
fprintf('Plot saved as "%s"\n', filename);

%% Generate Supplemental Table
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLE\n');
fprintf('========================================\n\n');

% Build the Values string
values_str = '';
n_str = '';

% Create age labels dynamically
age_labels_clean = cell(size(age_groups));
for k = 1:length(age_groups)
    temp_label = char(age_groups{k});
    age_labels_clean{k} = temp_label(3:end);
end

fprintf('Detected age groups:\n');
for k = 1:length(age_groups)
    fprintf('  %s -> %s\n', char(age_groups{k}), age_labels_clean{k});
end
fprintf('\n');

for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    values_str = [values_str, sprintf('\n%s:\n', age_label)];
    
    for j = 1:length(regions_ordered)
        region = regions_ordered{j};
        subset = data(data.Age_group == ag & data.Region == region, :);
        
        if ~isempty(subset)
            mean_val = mean(subset.BCAS1_density_mm2);
            sem_val = std(subset.BCAS1_density_mm2) / sqrt(height(subset));
            values_str = [values_str, sprintf('  %s: %.2f±%.2f\n', region, mean_val, sem_val)];
        end
    end
end

% Count total sections per age group
for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    n_sections = sum(data.Age_group == ag);
    n_str = [n_str, sprintf('%s: %d sections\n', age_label, n_sections)];
end

% Build statistical test string
stat_test_str = sprintf('Dataset (0-24 months, n=%d sections):\n', height(data));
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict BCAS1 density with ', ...
    'categorical Age_group and Region (Calc vs. FG vs. CoS), ', ...
    'with interaction, and with random variable of section.\n\n'])];

% Add ANOVA results
age_group_idx = find(strcmp(anova_results.Term, 'Age_group'));
region_idx = find(strcmp(anova_results.Term, 'Region'));
region_age_group_idx = find(strcmp(anova_results.Term, 'Region:Age_group') | strcmp(anova_results.Term, 'Age_group:Region'));

stat_test_str = [stat_test_str, sprintf('Main effect of Age_group (categorical): F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_group_idx), anova_results.DF2(age_group_idx), ...
    anova_results.FStat(age_group_idx), anova_results.pValue(age_group_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_idx), anova_results.DF2(region_idx), ...
    anova_results.FStat(region_idx), anova_results.pValue(region_idx))];

stat_test_str = [stat_test_str, sprintf('Region × Age_group interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_age_group_idx), anova_results.DF2(region_age_group_idx), ...
    anova_results.FStat(region_age_group_idx), anova_results.pValue(region_age_group_idx))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f\n', lme.Rsquared.Ordinary)];

%% Perform post-hoc pairwise comparisons based on significant effects
fprintf('\n========================================\n');
fprintf('POST-HOC PAIRWISE COMPARISONS\n');
fprintf('========================================\n');
fprintf('Only performing post-hoc tests for significant main effects and interactions (p < 0.05)\n\n');

posthoc_results = {};

% Check which effects are significant
region_significant = anova_results.pValue(region_idx) < 0.05;
age_group_significant = anova_results.pValue(age_group_idx) < 0.05;
region_age_group_significant = anova_results.pValue(region_age_group_idx) < 0.05;

fprintf('Significant effects:\n');
fprintf('  Main effect of Region: %s (p=%.4f)\n', ...
    ternary(region_significant, 'YES', 'NO'), anova_results.pValue(region_idx));
fprintf('  Main effect of Age_group: %s (p=%.4f)\n', ...
    ternary(age_group_significant, 'YES', 'NO'), anova_results.pValue(age_group_idx));
fprintf('  Region × Age_group interaction: %s (p=%.4f)\n\n', ...
    ternary(region_age_group_significant, 'YES', 'NO'), anova_results.pValue(region_age_group_idx));

% Helper function for ternary operator
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

%% POST-HOC TEST 1: Region main effect (if significant)
if region_significant
    fprintf('\n--- POST-HOC: Region Comparisons (Main Effect) ---\n');
    fprintf('Comparing regions collapsed across age groups\n\n');
    
    region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
    
    for j = 1:length(region_pairs)
        region1 = region_pairs{j}{1};
        region2 = region_pairs{j}{2};
        
        data1 = data(data.Region == region1, :);
        data2 = data(data.Region == region2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.BCAS1_density_mm2, data2.BCAS1_density_mm2);
            
            mean1 = mean(data1.BCAS1_density_mm2);
            mean2 = mean(data2.BCAS1_density_mm2);
            
            comparison = sprintf('%s vs. %s', region1, region2);
            
            fprintf('  %s: ', comparison);
            fprintf('%.2f vs. %.2f, p=%.6f', mean1, mean2, p);
            
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                else
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
else
    fprintf('\n--- POST-HOC: Region Comparisons ---\n');
    fprintf('Skipped (main effect not significant, p=%.4f)\n', anova_results.pValue(region_idx));
end

%% POST-HOC TEST 2: Age_group main effect (if significant)
if age_group_significant
    fprintf('\n--- POST-HOC: Age_group Comparisons (Main Effect) ---\n');
    fprintf('Comparing age groups collapsed across regions\n\n');
    
    % Create all pairwise age group combinations
    age_group_pairs = {};
    for i = 1:length(age_groups)-1
        for j = i+1:length(age_groups)
            age_group_pairs{end+1} = {char(age_groups{i}), char(age_groups{j})};
        end
    end
    
    for j = 1:length(age_group_pairs)
        age1 = age_group_pairs{j}{1};
        age2 = age_group_pairs{j}{2};
        
        data1 = data(data.Age_group == age1, :);
        data2 = data(data.Age_group == age2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.BCAS1_density_mm2, data2.BCAS1_density_mm2);
            
            mean1 = mean(data1.BCAS1_density_mm2);
            mean2 = mean(data2.BCAS1_density_mm2);
            
            % Get clean labels
            age1_clean = age1(3:end);
            age2_clean = age2(3:end);
            
            comparison = sprintf('%s vs. %s', age1_clean, age2_clean);
            
            fprintf('  %s: ', comparison);
            fprintf('%.2f vs. %.2f, p=%.6f', mean1, mean2, p);
            
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                else
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
else
    fprintf('\n--- POST-HOC: Age_group Comparisons ---\n');
    fprintf('Skipped (main effect not significant, p=%.4f)\n', anova_results.pValue(age_group_idx));
end

%% POST-HOC TEST 3: Region × Age_group interaction (if significant)
if region_age_group_significant
    fprintf('\n--- POST-HOC: Region × Age_group Interaction ---\n');
    fprintf('Comparing regions within each age group\n\n');
    
    for i = 1:length(age_groups)
        ag = age_groups{i};
        age_label = age_labels_clean{i};
        
        fprintf('\n%s:\n', age_label);
        
        age_subset = data(data.Age_group == ag, :);
        
        if isempty(age_subset)
            fprintf('  No data\n');
            continue;
        end
        
        region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
        
        for j = 1:length(region_pairs)
            region1 = region_pairs{j}{1};
            region2 = region_pairs{j}{2};
            
            data1 = age_subset(age_subset.Region == region1, :);
            data2 = age_subset(age_subset.Region == region2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.BCAS1_density_mm2, data2.BCAS1_density_mm2);
                
                mean1 = mean(data1.BCAS1_density_mm2);
                mean2 = mean(data2.BCAS1_density_mm2);
                
                comparison = sprintf('%s, %s vs. %s, %s', region1, age_label, region2, age_label);
                
                fprintf('  %s vs. %s: ', region1, region2);
                fprintf('%.2f vs. %.2f, p=%.6f', mean1, mean2, p);
                
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                    else
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
else
    fprintf('\n--- POST-HOC: Region × Age_group Interaction ---\n');
    fprintf('Skipped (interaction not significant, p=%.4f)\n', anova_results.pValue(region_age_group_idx));
end

% Build significance string
significance_str = 'Post-hoc pairwise comparisons using Student''s t-test:\n';
significance_str = [significance_str, 'Only performed for significant main effects and interactions (p < 0.05)\n\n'];

if ~isempty(posthoc_results)
    for i = 1:length(posthoc_results)
        significance_str = [significance_str, posthoc_results{i}, '\n'];
    end
    significance_str = [significance_str, '\nAll other comparisons p>0.05'];
else
    significance_str = [significance_str, 'No significant pairwise comparisons found'];
end

%% ONE-SAMPLE T-TESTS for youngest age group (a_0-1.5 mo)
fprintf('\n========================================\n');
fprintf('ONE-SAMPLE T-TESTS\n');
fprintf('========================================\n');
fprintf('Testing if BCAS1 density in youngest age group (a_0-1.5 mo) is greater than 0\n');
fprintf('Null hypothesis: μ = 0\n');
fprintf('Alternative hypothesis: μ > 0 (right-tailed test)\n\n');

% Extract youngest age group data
youngest_data = data(data.Age_group == 'a_0-1.5 mo', :);

one_sample_results = {};

if isempty(youngest_data)
    fprintf('WARNING: No data found for age group "a_0-1.5 mo"\n');
    fprintf('Available age groups:\n');
    disp(categories(data.Age_group));
else
    fprintf('--- OVERALL (all regions combined) ---\n');
    fprintf('Sample size: %d sections\n', height(youngest_data));
    fprintf('Mean BCAS1 density: %.2f cells/mm²\n', mean(youngest_data.BCAS1_density_mm2));
    fprintf('SEM: %.2f cells/mm²\n', std(youngest_data.BCAS1_density_mm2) / sqrt(height(youngest_data)));
    
    [h, p, ci, stats] = ttest(youngest_data.BCAS1_density_mm2, 0, 'Tail', 'right');
    fprintf('t(%d) = %.4f, p = %.4e\n', stats.df, stats.tstat, p);
    fprintf('95%% CI: [%.2f, Inf]\n', ci(1));
    
    if h == 1
        fprintf('Result: SIGNIFICANT (p < 0.05)\n\n');
        if p < 0.001
            one_sample_results{end+1} = 'Overall (all regions): p<0.001';
        else
            one_sample_results{end+1} = sprintf('Overall (all regions): p=%.4e', p);
        end
    else
        fprintf('Result: NOT SIGNIFICANT (p >= 0.05)\n\n');
    end
    
    % Test each region separately
    fprintf('\n--- BY REGION ---\n');
    for r = 1:length(regions_ordered)
        region_name = regions_ordered{r};
        region_subset = youngest_data(youngest_data.Region == region_name, :);
        
        if ~isempty(region_subset)
            n = height(region_subset);
            mean_val = mean(region_subset.BCAS1_density_mm2);
            sem_val = std(region_subset.BCAS1_density_mm2) / sqrt(n);
            
            [h, p, ci, stats] = ttest(region_subset.BCAS1_density_mm2, 0, 'Tail', 'right');
            
            fprintf('\n%s:\n', region_name);
            fprintf('  n = %d sections\n', n);
            fprintf('  Mean±SEM = %.2f±%.2f cells/mm²\n', mean_val, sem_val);
            fprintf('  t(%d) = %.4f, p = %.4e\n', stats.df, stats.tstat, p);
            fprintf('  95%% CI: [%.2f, Inf]\n', ci(1));
            
            if h == 1
                fprintf('  Result: SIGNIFICANT (p < 0.05)\n');
                if p < 0.001
                    one_sample_results{end+1} = sprintf('%s: p<0.001', region_name);
                else
                    one_sample_results{end+1} = sprintf('%s: p=%.4e', region_name, p);
                end
            else
                fprintf('  Result: NOT SIGNIFICANT (p >= 0.05)\n');
            end
        else
            fprintf('\n%s: No data available\n', region_name);
        end
    end
end

% Add one-sample test results to significance string
if ~isempty(one_sample_results)
    significance_str = [significance_str, '\n\nOne-sample t-tests (youngest age group a_0-1.5 mo > 0):\n'];
    for i = 1:length(one_sample_results)
        significance_str = [significance_str, one_sample_results{i}, '\n'];
    end
end

%% Save supplemental table
supp_table = table(...
    {'Fig. S8'}, ...
    {'BCAS1 density (cells/mm²) of individual sections in Calc, CoS, and FG across age groups'}, ...
    {values_str}, ...
    {n_str}, ...
    {stat_test_str}, ...
    {significance_str}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table, 'BCAS1_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "BCAS1_Supplemental_Table.csv"\n');

% Also save a more readable text version
fid_supp = fopen('BCAS1_Supplemental_Table.txt', 'w');
fprintf(fid_supp, '========================================================\n');
fprintf(fid_supp, 'SUPPLEMENTAL TABLE - BCAS1 Density Analysis\n');
fprintf(fid_supp, '========================================================\n\n');

fprintf(fid_supp, 'Figure: Fig. S8\n\n');

fprintf(fid_supp, 'Measure:\n');
fprintf(fid_supp, 'BCAS1 density (cells/mm²) of individual sections in Calc, CoS, and FG across age groups\n\n');

fprintf(fid_supp, 'Values (Mean±SEM):\n');
fprintf(fid_supp, '------------------\n');
fprintf(fid_supp, values_str);

fprintf(fid_supp, '\n\nSample Sizes:\n');
fprintf(fid_supp, '-------------\n');
fprintf(fid_supp, n_str);

fprintf(fid_supp, '\n\nStatistical Tests:\n');
fprintf(fid_supp, '------------------\n');
fprintf(fid_supp, stat_test_str);

fprintf(fid_supp, '\n\n\nPost-hoc Comparisons and One-Sample Tests:\n');
fprintf(fid_supp, '-------------------------------------------\n');
fprintf(fid_supp, significance_str);

fprintf(fid_supp, '\n\n========================================================\n');
fclose(fid_supp);

fprintf('Readable supplemental table saved to "BCAS1_Supplemental_Table.txt"\n');

% Display preview of statistics
fprintf('\n========================================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Statistical Tests\n');
fprintf('========================================================\n\n');
fprintf(stat_test_str);

fprintf('\n========================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Post-hoc Comparisons\n');
fprintf('========================================\n\n');
fprintf(significance_str);

fprintf('\n\n=== All outputs complete ===\n');
fprintf('Files generated:\n');
fprintf('  1. BCAS1_density_by_region_age.png\n');
fprintf('  2. BCAS1_Supplemental_Table.csv\n');
fprintf('  3. BCAS1_Supplemental_Table.txt\n\n');

fprintf('=== ANALYSIS COMPLETE ===\n\n');
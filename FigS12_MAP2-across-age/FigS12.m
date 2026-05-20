% MAP2 Coverage Analysis
% Linear Mixed-Effects Model: MAP2_coverage ~ Region*Age_group + (1|Slide_number)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('MAP2_coverage.csv');

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

%% Fit Linear Mixed-Effects Model - Full Dataset with categorical Age_group
fprintf('\nFitting linear mixed-effects model (Full Dataset)...\n');
fprintf('Model formula: MAP2_coverage ~ Region*Age_group + (1|Slide_number)\n');
fprintf('Using REML estimation\n\n');

lme = fitlme(data, 'MAP2_coverage ~ Region * Age_group + (1|Slide_number)', 'FitMethod', 'REML');

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

%% CUSTOM PLOT 1: Full Dataset - Mean ± SEM by Age Group and Region
figure('Position', [100, 100, 1000, 600]);

% Define custom colors: Calc=purple, FG=pink, CoS=green
region_colors = containers.Map({'Calc', 'FG', 'CoS'}, ...
                               {[0.6, 0.2, 0.8], [1, 0.4, 0.7], [0.2, 0.8, 0.4]});

age_groups = categories(data.Age_group);
n_groups = length(age_groups);
regions_ordered = {'Calc', 'CoS', 'FG'};

for i = 1:length(regions_ordered)
    region_name = regions_ordered{i};
    region_data = data(data.Region == region_name, :);
    
    means = zeros(n_groups, 1);
    sems = zeros(n_groups, 1);
    x_positions = 1:n_groups;
    
    for j = 1:n_groups
        group_data = region_data(region_data.Age_group == age_groups{j}, :);
        if ~isempty(group_data)
            means(j) = mean(group_data.MAP2_coverage);
            sems(j) = std(group_data.MAP2_coverage) / sqrt(height(group_data));
        else
            means(j) = NaN;
            sems(j) = NaN;
        end
    end
    
    % Plot mean as dots with error bars
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
ylabel('MAP2 Coverage (%)', 'FontSize', 14, 'FontWeight', 'bold');
title('MAP2 Coverage Across Development - Full Dataset', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

saveas(gcf, 'MAP2_age_group_means_full.png');
fprintf('\nFull dataset mean±SEM plot saved as "MAP2_age_group_means_full.png"\n');

%% Analyze infant subset (Age < 25 months)
fprintf('\n========================================\n');
fprintf('INFANT SUBSET ANALYSIS (Age < 25 months)\n');
fprintf('========================================\n\n');

infant_data = data(data.Age < 25, :);

% Drop unused categorical levels after subsetting
infant_data.Region = removecats(infant_data.Region);
infant_data.Slide_number = removecats(infant_data.Slide_number);
infant_data.Age_group = removecats(infant_data.Age_group);

fprintf('Infant subset summary:\n');
fprintf('Total observations: %d\n', height(infant_data));
fprintf('Number of slides: %d\n', length(unique(infant_data.Slide_number)));
fprintf('Age range: %.1f - %.1f months\n\n', min(infant_data.Age), max(infant_data.Age));

fprintf('Observations per region (infant):\n');
disp(tabulate(infant_data.Region));

fprintf('Observations per age group (infant):\n');
disp(tabulate(infant_data.Age_group));

fprintf('\nFitting model on infant subset...\n');
lme_infant = fitlme(infant_data, 'MAP2_coverage ~ Region * Age_group + (1|Slide_number)', ...
                    'FitMethod', 'REML');

fprintf('\nInfant Model Results:\n');
fprintf('=====================\n');
disp(lme_infant);

fprintf('\n=== Infant Fixed Effects ===\n');
disp(lme_infant.Coefficients);

fprintf('\n=== Infant Random Effects ===\n');
[psi_infant, mse_infant] = covarianceParameters(lme_infant);
slide_SD_infant = sqrt(psi_infant{1});
residual_SD_infant = sqrt(mse_infant);
ICC_infant = psi_infant{1} / (psi_infant{1} + mse_infant);

fprintf('Slide_number random intercept SD: %.4f\n', slide_SD_infant);
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

%% CUSTOM PLOT 2: Infant Dataset - Mean ± SEM by Age Group and Region
figure('Position', [100, 100, 1000, 600]);

infant_age_groups = categories(infant_data.Age_group);
n_groups_infant = length(infant_age_groups);
regions_ordered = {'Calc', 'CoS', 'FG'};

for i = 1:length(regions_ordered)
    region_name = regions_ordered{i};
    region_data = infant_data(infant_data.Region == region_name, :);
    
    means = zeros(n_groups_infant, 1);
    sems = zeros(n_groups_infant, 1);
    x_positions = 1:n_groups_infant;
    
    for j = 1:n_groups_infant
        group_data = region_data(region_data.Age_group == infant_age_groups{j}, :);
        if ~isempty(group_data)
            means(j) = mean(group_data.MAP2_coverage);
            sems(j) = std(group_data.MAP2_coverage) / sqrt(height(group_data));
        else
            means(j) = NaN;
            sems(j) = NaN;
        end
    end
    
    % Plot mean as dots with error bars
    errorbar(x_positions, means, sems, 'o', ...
             'Color', region_colors(region_name), ...
             'MarkerFaceColor', region_colors(region_name), ...
             'MarkerSize', 10, ...
             'LineWidth', 2, ...
             'CapSize', 8, ...
             'DisplayName', region_name);
    hold on;
end

set(gca, 'XTick', 1:n_groups_infant, 'XTickLabel', infant_age_groups);
xtickangle(45);
xlabel('Age Group', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('MAP2 Coverage (%)', 'FontSize', 14, 'FontWeight', 'bold');
title('MAP2 Coverage During Infancy (< 25 months)', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

saveas(gcf, 'MAP2_age_group_means_infant.png');
fprintf('Infant mean±SEM plot saved as "MAP2_age_group_means_infant.png"\n');

%% Compare full vs infant models
fprintf('\n========================================\n');
fprintf('MODEL COMPARISON: Full vs Infant\n');
fprintf('========================================\n\n');

fprintf('%-25s %15s %15s\n', 'Metric', 'Full Dataset', 'Infant Only');
fprintf('%s\n', repmat('-', 1, 60));
fprintf('%-25s %15d %15d\n', 'N observations', height(data), height(infant_data));
fprintf('%-25s %15d %15d\n', 'N slides', length(unique(data.Slide_number)), length(unique(infant_data.Slide_number)));
fprintf('%-25s %15.2f %15.2f\n', 'AIC', lme.ModelCriterion.AIC, lme_infant.ModelCriterion.AIC);
fprintf('%-25s %15.2f %15.2f\n', 'BIC', lme.ModelCriterion.BIC, lme_infant.ModelCriterion.BIC);
fprintf('%-25s %15.4f %15.4f\n', 'R-squared', lme.Rsquared.Ordinary, lme_infant.Rsquared.Ordinary);
fprintf('%-25s %15.4f %15.4f\n', 'ICC', ICC, ICC_infant);

fprintf('\n%-25s %15s %15s\n', 'Fixed Effect p-values', 'Full Dataset', 'Infant Only');
fprintf('%s\n', repmat('-', 1, 60));

age_idx_full = find(strcmp(anova_results.Term, 'Age_group'));
age_idx_infant = find(strcmp(anova_infant.Term, 'Age_group'));
fprintf('%-25s %15.6f %15.6f\n', 'Age_group', anova_results.pValue(age_idx_full), anova_infant.pValue(age_idx_infant));

region_idx_full = find(strcmp(anova_results.Term, 'Region'));
region_idx_infant = find(strcmp(anova_infant.Term, 'Region'));
fprintf('%-25s %15.6f %15.6f\n', 'Region', anova_results.pValue(region_idx_full), anova_infant.pValue(region_idx_infant));

int_idx_full = find(strcmp(anova_results.Term, 'Region:Age_group') | strcmp(anova_results.Term, 'Age_group:Region'));
int_idx_infant = find(strcmp(anova_infant.Term, 'Region:Age_group') | strcmp(anova_infant.Term, 'Age_group:Region'));
fprintf('%-25s %15.6f %15.6f\n', 'Region:Age_group', anova_results.pValue(int_idx_full), anova_infant.pValue(int_idx_infant));

%% Generate Supplemental Table for Publication
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLE\n');
fprintf('========================================\n\n');

% Get actual age groups from data
age_groups = categories(data.Age_group);
regions_ordered = {'Calc', 'FG', 'CoS'};

% Build the Values string
values_str = '';
n_str = '';

% Create age labels dynamically (remove prefix letter and underscore)
age_labels_clean = cell(size(age_groups));
for k = 1:length(age_groups)
    % Remove the letter prefix (e.g., 'a_', 'b_', etc.)
    temp_label = char(age_groups{k});
    age_labels_clean{k} = temp_label(3:end);  % Skip first 2 characters (letter + underscore)
end

fprintf('Detected age groups:\n');
for k = 1:length(age_groups)
    fprintf('  %s -> %s\n', char(age_groups{k}), age_labels_clean{k});
end
fprintf('\n');

for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    values_str = [values_str, age_label, ':\n'];
    
    % Count sections for this age group
    n_sections = sum(data.Age_group == ag);
    n_str = [n_str, age_label, ': ', num2str(n_sections), ' sections\n'];
    
    for j = 1:length(regions_ordered)
        region = regions_ordered{j};
        subset = data(data.Age_group == ag & data.Region == region, :);
        
        if ~isempty(subset)
            mean_val = mean(subset.MAP2_coverage);
            sem_val = std(subset.MAP2_coverage) / sqrt(height(subset));
            values_str = [values_str, sprintf('%s: %.2f±%.2f\n', region, mean_val, sem_val)];
        end
    end
end

% Build statistical test string - FULL DATASET
stat_test_str = sprintf('FULL DATASET (All ages: 0-300 months, n=%d sections):\n', height(data));
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict MAP2 coverage with ', ...
    'categorical Age_group and Region (Calc vs. FG vs. CoS), ', ...
    'with interaction, and with random variable of section.\n\n'])];

% Add ANOVA results - Full dataset
age_idx = find(strcmp(anova_results.Term, 'Age_group'));
region_idx = find(strcmp(anova_results.Term, 'Region'));
interaction_idx = find(strcmp(anova_results.Term, 'Region:Age_group') | strcmp(anova_results.Term, 'Age_group:Region'));

stat_test_str = [stat_test_str, sprintf('Main effect of Age_group to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_idx), ...
    anova_results.DF2(age_idx), ...
    anova_results.FStat(age_idx), ...
    anova_results.pValue(age_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Region to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_idx), ...
    anova_results.DF2(region_idx), ...
    anova_results.FStat(region_idx), ...
    anova_results.pValue(region_idx))];

stat_test_str = [stat_test_str, sprintf('Interaction effect between Age_group and Region to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(interaction_idx), ...
    anova_results.DF2(interaction_idx), ...
    anova_results.FStat(interaction_idx), ...
    anova_results.pValue(interaction_idx))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f\n\n', lme.Rsquared.Ordinary)];

% Add infant-only model statistics
stat_test_str = [stat_test_str, sprintf('\nINFANT SUBSET (Age < 25 months, n=%d sections):\n', height(infant_data))];
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict MAP2 coverage with ', ...
    'categorical Age_group and Region (Calc vs. FG vs. CoS), ', ...
    'with interaction, and with random variable of section.\n\n'])];

% Add ANOVA results - Infant dataset
age_idx_infant = find(strcmp(anova_infant.Term, 'Age_group'));
region_idx_infant = find(strcmp(anova_infant.Term, 'Region'));
interaction_idx_infant = find(strcmp(anova_infant.Term, 'Region:Age_group') | strcmp(anova_infant.Term, 'Age_group:Region'));

stat_test_str = [stat_test_str, sprintf('Main effect of Age_group to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_infant.DF1(age_idx_infant), ...
    anova_infant.DF2(age_idx_infant), ...
    anova_infant.FStat(age_idx_infant), ...
    anova_infant.pValue(age_idx_infant))];

stat_test_str = [stat_test_str, sprintf('Main effect of Region to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_infant.DF1(region_idx_infant), ...
    anova_infant.DF2(region_idx_infant), ...
    anova_infant.FStat(region_idx_infant), ...
    anova_infant.pValue(region_idx_infant))];

stat_test_str = [stat_test_str, sprintf('Interaction effect between Age_group and Region to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_infant.DF1(interaction_idx_infant), ...
    anova_infant.DF2(interaction_idx_infant), ...
    anova_infant.FStat(interaction_idx_infant), ...
    anova_infant.pValue(interaction_idx_infant))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f', lme_infant.Rsquared.Ordinary)];

% Perform post-hoc pairwise comparisons
fprintf('Performing post-hoc pairwise comparisons...\n');

posthoc_results = {};

% PART 1: Region comparisons within each age group (for significant interaction)
fprintf('\nRegion comparisons within each age group:\n');
for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    
    % Get data for this age group
    age_subset = data(data.Age_group == ag, :);
    
    % Compare all region pairs within this age group
    region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
    
    for j = 1:length(region_pairs)
        region1 = region_pairs{j}{1};
        region2 = region_pairs{j}{2};
        
        data1 = age_subset(age_subset.Region == region1, :);
        data2 = age_subset(age_subset.Region == region2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.MAP2_coverage, data2.MAP2_coverage);
            
            comparison = sprintf('%s, %s vs. %s, %s', region1, age_label, region2, age_label);
            
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

% PART 2: Age group comparisons within each region (if main effect of age is significant)
fprintf('\nAge group comparisons within each region:\n');
for r = 1:length(regions_ordered)
    region = regions_ordered{r};
    
    % Get data for this region
    region_subset = data(data.Region == region, :);
    
    % Compare consecutive age groups
    for i = 1:length(age_groups)-1
        for j = i+1:length(age_groups)
            data1 = region_subset(region_subset.Age_group == age_groups{i}, :);
            data2 = region_subset(region_subset.Age_group == age_groups{j}, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.MAP2_coverage, data2.MAP2_coverage);
                
                comparison = sprintf('%s, %s vs. %s, %s', region, age_labels_clean{i}, region, age_labels_clean{j});
                
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

% PART 3: Overall age group comparisons (collapsed across regions)
fprintf('\nOverall age group comparisons (collapsed across regions):\n');
for i = 1:length(age_groups)-1
    for j = i+1:length(age_groups)
        group1_data = data(data.Age_group == age_groups{i}, :);
        group2_data = data(data.Age_group == age_groups{j}, :);
        
        [h, p] = ttest2(group1_data.MAP2_coverage, group2_data.MAP2_coverage);
        
        comparison = sprintf('%s vs. %s (all regions)', age_labels_clean{i}, age_labels_clean{j});
        
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

% PART 4: Overall region comparisons (collapsed across age groups)
fprintf('\nOverall region comparisons (collapsed across age groups):\n');
region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};

for j = 1:length(region_pairs)
    region1 = region_pairs{j}{1};
    region2 = region_pairs{j}{2};
    
    data1 = data(data.Region == region1, :);
    data2 = data(data.Region == region2, :);
    
    if ~isempty(data1) && ~isempty(data2)
        [h, p] = ttest2(data1.MAP2_coverage, data2.MAP2_coverage);
        
        comparison = sprintf('%s vs. %s (all ages)', region1, region2);
        
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

% Build significance string
significance_str = 'Post-hoc pairwise comparisons using Student''s t-test:\n\n';
if ~isempty(posthoc_results)
    for i = 1:length(posthoc_results)
        significance_str = [significance_str, posthoc_results{i}, '\n'];
    end
    significance_str = [significance_str, '\nAll other comparisons p>0.05'];
else
    significance_str = [significance_str, 'No significant pairwise comparisons (all p>0.05)'];
end

% Create table structure
supp_table = table(...
    {'Fig. S12bc'}, ...
    {'MAP2 coverage (%) of individual sections in Calc, CoS, and FG across age groups'}, ...
    {values_str}, ...
    {n_str}, ...
    {stat_test_str}, ...
    {significance_str}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table, 'MAP2_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "MAP2_Supplemental_Table.csv"\n');

% Also save a more readable text version
fid_supp = fopen('MAP2_Supplemental_Table.txt', 'w');
fprintf(fid_supp, '========================================================\n');
fprintf(fid_supp, 'SUPPLEMENTAL TABLE - MAP2 Coverage Analysis\n');
fprintf(fid_supp, '========================================================\n\n');

fprintf(fid_supp, 'Figure: Fig. S12bc\n\n');

fprintf(fid_supp, 'Measure:\n');
fprintf(fid_supp, 'MAP2 coverage (%%) of individual sections in Calc, CoS, and FG across age groups\n\n');

fprintf(fid_supp, 'Values (Mean±SEM):\n');
fprintf(fid_supp, '------------------\n');
fprintf(fid_supp, values_str);

fprintf(fid_supp, '\n\nSample Sizes:\n');
fprintf(fid_supp, '-------------\n');
fprintf(fid_supp, n_str);

fprintf(fid_supp, '\n\nStatistical Tests:\n');
fprintf(fid_supp, '------------------\n');
fprintf(fid_supp, stat_test_str);

fprintf(fid_supp, '\n\n\nPost-hoc Comparisons:\n');
fprintf(fid_supp, '---------------------\n');
fprintf(fid_supp, significance_str);

fprintf(fid_supp, '\n\n========================================================\n');
fclose(fid_supp);

fprintf('Readable supplemental table saved to "MAP2_Supplemental_Table.txt"\n');

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
fprintf('  1. MAP2_age_group_means_full.png\n');
fprintf('  2. MAP2_age_group_means_infant.png\n');
fprintf('  3. MAP2_Supplemental_Table.csv\n');
fprintf('  4. MAP2_Supplemental_Table.txt\n\n');

fprintf('=== ANALYSIS COMPLETE ===\n\n');
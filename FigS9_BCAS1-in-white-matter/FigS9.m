% One-Sample t-tests: Cell Density vs Zero by Age Group
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('FigS9.csv');

%% Display data summary
fprintf('========================================\n');
fprintf('ONE-SAMPLE T-TESTS: CELL DENSITY vs ZERO\n');
fprintf('========================================\n\n');

fprintf('Dataset Summary:\n');
fprintf('----------------\n');
fprintf('Total observations: %d\n', height(data));
fprintf('Variable: cell_density_per_mm2\n');
fprintf('Grouping variable: age_group\n\n');

%% Convert age_group to categorical if necessary
if iscell(data.age_group)
    data.age_group = categorical(data.age_group);
end

%% Get unique age groups
age_groups = unique(data.age_group);
fprintf('Age Groups:\n');
disp(age_groups);
fprintf('Number of age groups: %d\n\n', length(age_groups));

%% One-sample t-tests for each age group
fprintf('========================================\n');
fprintf('ONE-SAMPLE T-TESTS (vs 0)\n');
fprintf('========================================\n\n');

fprintf('%-15s %8s %10s %10s %12s %12s %10s\n', ...
    'Age Group', 'n', 'Mean', 'SEM', 't-stat', 'p-value', 'Sig');
fprintf('%s\n', repmat('-', 1, 85));

results = [];

for i = 1:length(age_groups)
    % Extract data for this age group
    group_data = data(data.age_group == age_groups(i), :);
    density = group_data.cell_density_per_mm2;
    density_clean = density(~isnan(density));
    
    % Calculate statistics
    n = length(density_clean);
    m = mean(density_clean);
    sem = std(density_clean) / sqrt(n);
    
    % One-sample t-test vs 0
    [h, p, ci, stats] = ttest(density_clean, 0);
    
    % Determine significance
    if p < 0.001
        sig = '***';
    elseif p < 0.01
        sig = '**';
    elseif p < 0.05
        sig = '*';
    else
        sig = 'ns';
    end
    
    % Display results
    fprintf('%-15s %8d %10.2f %10.2f %12.4f %12.6f %10s\n', ...
        char(age_groups(i)), n, m, sem, stats.tstat, p, sig);
    
    % Store results
    results(i).age_group = char(age_groups(i));
    results(i).n = n;
    results(i).mean = m;
    results(i).sem = sem;
    results(i).tstat = stats.tstat;
    results(i).df = stats.df;
    results(i).pvalue = p;
    results(i).sig = sig;
    results(i).ci_lower = ci(1);
    results(i).ci_upper = ci(2);
end

fprintf('\n');
fprintf('* p < 0.05; ** p < 0.01; *** p < 0.001\n\n');

%% Create bar plot with significance
fprintf('Creating bar plot...\n');

figure('Position', [100, 100, 900, 600]);

means = [results.mean];
sems = [results.sem];

bar(1:length(age_groups), means, 'FaceColor', [0.3, 0.6, 0.9]);
hold on;
errorbar(1:length(age_groups), means, sems, 'k', 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 10);

% Add significance stars
for i = 1:length(age_groups)
    if ~strcmp(results(i).sig, 'ns')
        text(i, means(i) + sems(i) + max(means)*0.05, results(i).sig, ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
    end
end

% Add reference line at zero
yline(0, 'r--', 'LineWidth', 2);

hold off;

ylabel('Cell Density (per mm²) - Mean ± SEM', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Age Group', 'FontSize', 12, 'FontWeight', 'bold');
title('Cell Density by Age Group (One-Sample t-test vs 0)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', 1:length(age_groups), 'XTickLabel', cellstr(age_groups));
grid on;
set(gca, 'GridAlpha', 0.3);

saveas(gcf, 'CellDensity_OneSample_ttest.png');
saveas(gcf, 'CellDensity_OneSample_ttest.fig');

fprintf('Plot saved.\n\n');

%% Save results to file
fprintf('Saving results to text file...\n');

fid = fopen('CellDensity_OneSample_Results.txt', 'w');
fprintf(fid, '========================================================\n');
fprintf(fid, 'ONE-SAMPLE T-TESTS: CELL DENSITY vs ZERO\n');
fprintf(fid, '========================================================\n\n');

fprintf(fid, 'Dataset: FigS9.csv\n');
fprintf(fid, 'Date: %s\n\n', datestr(now));

fprintf(fid, 'Null hypothesis: Mean cell density = 0\n');
fprintf(fid, 'Alternative hypothesis: Mean cell density ≠ 0\n\n');

fprintf(fid, '%-15s %8s %10s %10s %12s %12s %10s\n', ...
    'Age Group', 'n', 'Mean', 'SEM', 't-stat', 'p-value', 'Sig');
fprintf(fid, '%s\n', repmat('-', 1, 85));

for i = 1:length(results)
    fprintf(fid, '%-15s %8d %10.2f %10.2f %12.4f %12.6f %10s\n', ...
        results(i).age_group, results(i).n, results(i).mean, results(i).sem, ...
        results(i).tstat, results(i).pvalue, results(i).sig);
end

fprintf(fid, '\n* p < 0.05; ** p < 0.01; *** p < 0.001\n');
fprintf(fid, '\n========================================================\n');

fclose(fid);

fprintf('Results saved to "CellDensity_OneSample_Results.txt"\n\n');

%% Save to CSV
summary_table = struct2table(results);
writetable(summary_table, 'CellDensity_OneSample_Summary.csv');
fprintf('Summary table saved to "CellDensity_OneSample_Summary.csv"\n\n');

fprintf('=== ANALYSIS COMPLETE ===\n\n');
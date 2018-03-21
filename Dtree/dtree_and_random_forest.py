# coding:utf-8

# ====== Import Libraries

from __futrue__ import division

from IPython.display import Image, display
%matplotlib inline
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.datasets import make_moons
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier, DecisionTreeRegressor, export_graphviz
from treeinterpreter import treeinterpreter as ti
import pydotplus

from tree_interp_functions import *

# Set default matplotlib settings
plt.rcParams['figure.figsize'] = (10, 7)
plt.rcParams['lines.linewidth'] = 3
plt.rcParams['figure.titlesize'] = 26
plt.rcParams['axes.labelsize'] = 18
plt.rcParams['axes.titlesize'] = 22
plt.rcParams['xtick.labelsize'] = 14
plt.rcParams['ytick.labelsize'] = 14
plt.rcParams['legend.fontsize'] = 16

# Set seaborn colours
sns.set_style('darkgrid')
sns.set_palette('colorblind')
blue, green, red, purple, yellow, cyan = sns.color_palette('colorblind')

# ========= How do Decision Trees work? =========

light_blue, dark_blue, light_green, dark_green, light_red, dark_red = sns.color_palette('Paired')
x, z = make_moons(noise=0.20, random_state=5)
df = pd.DataFrame({'z': z,
                   'x': x[:, 0],
                   'y': x[:, 1]
                  })

md_list = [1, 2, 5, 10]
fig, ax = plt.subplots(2, 2)

fig.set_figheight(10)
fig.set_figwidth(10)
for i in xrange(len(md_list)):
    md = md_list[i]
    ix_0 = int(np.floor(i/2))
    ix_1 = i%2
    
    circle_dt_clf = DecisionTreeClassifier(max_depth=md, random_state=0)
    circle_dt_clf.fit(df[['x', 'y']], df['z'])

    xx, yy = np.meshgrid(np.linspace(df.x.min() - 0.5, df.x.max() + 0.5, 50),
                         np.linspace(df.y.min() - 0.5, df.y.max() + 0.5, 50))
    z_pred = circle_dt_clf.predict(zip(xx.reshape(-1), yy.reshape(-1)))
    z_pred = np.array([int(j) for j in z_pred.reshape(-1)])\
        .reshape(len(xx), len(yy))

    ax[ix_0, ix_1].contourf(xx, yy, z_pred, cmap=plt.get_cmap('GnBu'))

    df.query('z == 0').plot('x', 'y', kind='scatter',
                            s=40, c=green, ax=ax[ix_0, ix_1])
    df.query('z == 1').plot('x', 'y', kind='scatter',
                            s=40, c=light_blue, ax=ax[ix_0, ix_1])
    
    ax[ix_0, ix_1].set_title('Max Depth: {}'.format(md))
    ax[ix_0, ix_1].set_xticks([], [])
    ax[ix_0, ix_1].set_yticks([], [])
    ax[ix_0, ix_1].set_xlabel('')
    ax[ix_0, ix_1].set_ylabel('')

plt.tight_layout()
plt.savefig('plots/dt_iterations.png')

# ======== Load Data ======

column_names = ["sex", "length", "diameter", "height", "whole weight", 
                "shucked weight", "viscera weight", "shell weight", "rings"]
abalone_df = pd.read_csv('abalone.csv', names=column_names)
abalone_df['sex'] = abalone_df['sex'].map({'F': 0, 'M': 1, 'I': 2})
abalone_df['y'] = abalone_df.rings.map(lambda x: 1 if x > 9 else 0)
# abalone_df.head()

# train/test split of the data
abalone_train, abalone_test = train_test_split(abalone_df, test_size=0.2,
                                               random_state=0)

X_train = abalone_train.drop(['sex', 'rings', 'y'], axis=1)
y_train_bin_clf = abalone_train.y
y_train_multi_clf = abalone_train.sex
y_train_reg = abalone_train.rings

X_test = abalone_test.drop(['sex', 'rings', 'y'], axis=1)
y_test_bin_clf = abalone_test.y
y_test_multi_clf = abalone_test.sex
y_test_reg = abalone_test.rings

X_train = X_train.copy().reset_index(drop=True)
y_train_bin_clf = y_train_bin_clf.copy().reset_index(drop=True)
y_train_multi_clf = y_train_multi_clf.copy().reset_index(drop=True)
y_train_reg = y_train_reg.copy().reset_index(drop=True)

X_test = X_test.copy().reset_index(drop=True)
y_test_bin_clf = y_test_bin_clf.copy().reset_index(drop=True)
y_test_multi_clf = y_test_multi_clf.copy().reset_index(drop=True)
y_test_reg = y_test_reg.copy().reset_index(drop=True)

# =========== Build Model ===========
# build simple decision tree and random forest model.
dt_bin_clf = DecisionTreeClassifier(criterion='entropy', max_depth=3, random_state=0)
dt_bin_clf.fit(X_train, y_train_bin_clf)

dt_multi_clf = DecisionTreeClassifier(criterion='entropy', max_depth=2, random_state=0)
dt_multi_clf.fit(X_train, y_train_multi_clf)

dt_reg = DecisionTreeRegressor(criterion='mse', max_depth=3, random_state=0)
dt_reg.fit(X_train, y_train_reg)

# 

rf_bin_clf = RandomForestClassifier(criterion='entropy', max_depth=10, n_estimators=100, random_state=0)
rf_bin_clf.fit(X_train, y_train_bin_clf)

rf_multi_clf = RandomForestClassifier(criterion='entropy', max_depth=10, n_estimators=100, random_state=0)
rf_multi_clf.fit(X_train, y_train_multi_clf)

rf_reg = RandomForestRegressor(criterion='mse', max_depth=10, n_estimators=100, random_state=0)
rf_reg.fit(X_train, y_train_reg)

# ===== Create Feature Contribution =======
dt_bin_clf_pred, dt_bin_clf_bias, dt_bin_clf_contrib = ti.predict(dt_bin_clf, X_test)
rf_bin_clf_pred, rf_bin_clf_bias, rf_bin_clf_contrib = ti.predict(rf_bin_clf, X_test)

dt_multi_clf_pred, dt_multi_clf_bias, dt_multi_clf_contrib = ti.predict(dt_multi_clf, X_test)
rf_multi_clf_pred, rf_multi_clf_bias, rf_multi_clf_contrib = ti.predict(rf_multi_clf, X_test)

dt_reg_pred, dt_reg_bias, dt_reg_contrib = ti.predict(dt_reg, X_test)
rf_reg_pred, rf_reg_bias, rf_reg_contrib = ti.predict(rf_reg, X_test)

# ====== Visualizing Decision Trees ======
reg_dot_data = export_graphviz(dt_reg, out_file=None, feature_names=X_train.columns)
reg_graph = pydotplus.graph_from_dot_data(reg_dot_data)
reg_graph.write_png('plots/reg_dt_path.png')
Image(reg_graph.create_png())


bin_clf_dot_data = export_graphviz(dt_bin_clf, out_file=None, feature_names=X_train.columns)
bin_clf_graph = pydotplus.graph_from_dot_data(bin_clf_dot_data)
reg_graph.write_png('plots/bin_clf_dt_path.png')
Image(bin_clf_graph.create_png())

multi_clf_dot_data = export_graphviz(dt_multi_clf, out_file=None, feature_names=X_train.columns)
multi_clf_graph = pydotplus.graph_from_dot_data(multi_clf_dot_data)
multi_clf_graph.write_png('plots/multi_clf_dt_path.png')
Image(multi_clf_graph.create_png())

# ==== Contributions ========
# Regression Contributions

# Find abalones that are in the left-most leaf
X_test[(X_test['shell weight'] <= 0.0587) & (X_test['length'] <= 0.2625)].head()

df, true_label, pred = plot_obs_feature_contrib(dt_reg,
                                                dt_reg_contrib,
                                                X_test,
                                                y_test_reg,
                                                3,
                                                order_by='contribution'
                                               )
plt.tight_layout()
plt.savefig('plots/contribution_plot_dt_reg.png')

df, true_label, score = plot_obs_feature_contrib(dt_reg,
                                                 dt_reg_contrib,
                                                 X_test,
                                                 y_test_reg,
                                                 3,
                                                 order_by='contribution',
                                                 violin=True
                                                )
plt.tight_layout()
plt.savefig('plots/contribution_plot_violin_dt_reg.png')

# ======= Decision Tree Features VS. Contributions

plot_single_feat_contrib('shell weight', dt_reg_contrib, X_test, class_index=1)
plt.savefig('plots/shell_weight_contribution_dt.png')

plot_single_feat_contrib('shucked weight', dt_reg_contrib, X_test, class_index=1)
plt.savefig('plots/shucked_weight_contribution_dt.png')

# ======= Extending to Random Forests =========
df, true_label, pred = plot_obs_feature_contrib(rf_reg,
                                                rf_reg_contrib,
                                                X_test,
                                                y_test_reg,
                                                3,
                                                order_by='contribution'
                                               )
plt.tight_layout()
plt.savefig('plots/contribution_plot_rf.png')

df = plot_obs_feature_contrib(rf_reg,
                              rf_reg_contrib,
                              X_test,
                              y_test_reg,
                              3,
                              order_by='contribution',
                              violin=True
                             )
plt.tight_layout()
plt.savefig('plots/contribution_plot_violin_rf.png')

plot_single_feat_contrib('shell weight', rf_reg_contrib, X_test,
                         class_index=1, add_smooth=True, frac=0.3)
plt.savefig('plots/shell_weight_contribution_rf.png')

plot_single_feat_contrib('shucked weight', rf_reg_contrib, X_test,
                         class_index=1, add_smooth=True, frac=0.3)
plt.savefig('plots/shucked_weight_contribution_rf.png')

abalone_test.plot(x='shucked weight', y='rings', kind='scatter')
plt.title('Number of Rings vs. Shucked Weight')
plt.ylabel('Number of Rings')
plt.tight_layout()

plt.savefig('plots/num_rings_vs_shucked_weight.png')

plot_single_feat_contrib('diameter', rf_reg_contrib, X_test,
                         class_index=1, add_smooth=True, frac=0.3)
plt.savefig('plots/diameter_contribution_rf.png')


# ====== Multi-class classification =======

# show data
X_test[(X_test['viscera weight'] <= 0.1622) & (X_test['shell weight'] <= 0.1285)].head()

df, true_label, scores = plot_obs_feature_contrib(dt_multi_clf,
                                                  dt_multi_clf_contrib,
                                                  X_test,
                                                  y_test_multi_clf,
                                                  3,
                                                  class_index=2,
                                                  order_by='contribution'
                                                 )
true_value_list = ['Female', 'Male', 'Infant']
score_dict = zip(true_value_list, scores)
title = 'True Value: {}\nScores: {}'.format(true_value_list[true_label],
                                            ', '.join(['{} - {}'.format(i, j) for i, j in score_dict]))
plt.title(title)
plt.savefig('plots/contribution_plot_multi_clf_dt.png')

df, true_label, scores = plot_obs_feature_contrib(dt_multi_clf,
                                                  dt_multi_clf_contrib,
                                                  X_test,
                                                  y_test_multi_clf,
                                                  3,
                                                  class_index=2,
                                                  order_by='contribution',
                                                  violin=True
                                                 )
true_value_list = ['Female', 'Male', 'Infant']
score_dict = zip(true_value_list, scores)
title = 'Contributions for Infant Class\nTrue Value: {}\nScores: {}'.format(true_value_list[true_label],
                                            ', '.join(['{} - {}'.format(i, j) for i, j in score_dict]))
plt.title(title)
plt.tight_layout()
plt.savefig('plots/contribution_plot_violin_multi_clf_dt.png')

colours = [blue, green, red]
class_names = ['Sex = {}'.format(s) for s in ('F', 'M', 'I')]

fig, ax = plt.subplots(1, 3, sharey=True)
fig.set_figwidth(20)

for i in xrange(3):
    plot_single_feat_contrib('shell weight', dt_multi_clf_contrib, X_test,
                             class_index=i, class_name=class_names[i],
                             c=colours[i], ax=ax[i])
    
plt.tight_layout()
plt.savefig('plots/shell_weight_contribution_by_sex_dt.png')

fig, ax = plt.subplots(1, 3, sharey=True)
fig.set_figwidth(20)

for i in xrange(3):
    plot_single_feat_contrib('shell weight', rf_multi_clf_contrib, X_test,
                             class_index=i, class_name=class_names[i],
                             add_smooth=True, c=colours[i], ax=ax[i])
    
plt.tight_layout()
plt.savefig('plots/shell_weight_contribution_by_sex_rf.png')




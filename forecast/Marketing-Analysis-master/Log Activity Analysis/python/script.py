import pandas as pd
import numpy as np
import seaborn as sns

def check(list):
    len = list.shape[0]
    start = pd.to_datetime(list.index[0])  # 1. register starting time
    output = pd.DataFrame()
    
    for i in range(1, len-1):
        
        # 2. get time difference
        time = (pd.to_datetime(newdata.index[i]) - pd.to_datetime(newdata.index[i-1])).seconds / 60        
        
        # 3. 
        if list.iloc[i-1][0] == list.iloc[i][0] and time < 10:                    
            pass
        
        else:
            # 4.
            df = pd.DataFrame(columns=('uuid', 'time', 'length'))
            df = df.append([{'uuid':list.iloc[i-1][0]}],ignore_index=True)
            df['uuid'] = list.iloc[i-1][0]
            df['time'] = start  
            df['length'] = (pd.to_datetime(list.index[i-1]) - start ).seconds / 60
            output = output.append(df)
            
            start = pd.to_datetime(list.index[i])
    # 5.
    output.index = output['time']
    return (output)
    
data = pd.read_csv('C:/Users/user/Documents/learner_item_data.csv')
newdata = data.sort_values(['uuid', 'created_at'], ascending=[1, 1]) # sorting by id and time
newdata.index = newdata['created_at'] # add index
print (newdata.head())

#organize
df = check(newdata)
print(df.head())

#data density distribution
sns.set_style('whitegrid')
g= sns.distplot(df.loc[:,'length'], bins = 50, hist= True)
g.set_title("Distribution of Session Length")

# active user
output = pd.DataFrame()
grp = df.groupby(df.index.date)

for key in grp:
    k = key[1].groupby(['uuid']).count().query('length>1') # 1st and 2nd steps
    
    if not k.empty: # 3rd and 4th steps
        
        # 3
        cf = pd.DataFrame(columns=('Date', 'Users')) 
        cf = cf.append([{'Date': key[0] }],ignore_index=True)
        cf['Users'] = k.shape[0]
        
        # 4
        li = list()
        for eds in range(k.shape[0]):
            tu = tuple([ str(k.index[eds]), k.iloc[eds]['length'] ])
            li.append(tu)
                
        cf['Details'] = [li]
        output = output.append(cf)

print(output.head())


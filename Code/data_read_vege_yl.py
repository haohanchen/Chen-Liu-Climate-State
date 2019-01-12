from pyhdf.SD import SD, SDC
import numpy as np
import matplotlib.pyplot as plt
import pprint
import glob
from datetime import datetime

def upscale(data,scale,fill_value,qt): 
    # a function to upscale data by a scale, qt is the quantile to be returned
    dim1 = np.array(data.shape)
    dim2 = (dim1/scale).astype(int)
    data_upscale = np.zeros(dim2)
    for r in range(dim2[0]):
        for c in range(dim2[1]):
            block = data[r*scale:(r+1)*scale,c*scale:(c+1)*scale]
            block = block[block!=fill_value]
            if len(block):
                data_upscale[r,c] = np.percentile(block,qt)
#                data_upscale[r,c] = np.mean(block)
            else:
                data_upscale[r,c] = fill_value
    return data_upscale

#%%
inpath = "I:/Data/NDVI/";
# origin coords
coords0 = np.array([-180,180,-90,90]);d0 = 0.05
x0, y0 = np.meshgrid(np.arange(coords0[0]+d0/2,coords0[1]+d0/2,d0),np.arange(coords0[3]+d0/2,coords0[2]+d0/2,-d0))

# destination coords
coords = np.array([-18,51,-35,38]);dd = 0.5
xx, yy = np.meshgrid(np.arange(coords[0]+dd/2,coords[1]+dd/2,dd),np.arange(coords[3]+dd/2,coords[2]+dd/2,-dd))
N = np.product(xx.shape)
xx1d = np.reshape(xx,[N,1])
yy1d = np.reshape(yy,[N,1])

idx = [i for i,em in enumerate(x0[0,:]) if (em>coords[0] and em<coords[1])]
idy = [i for i,em in enumerate(y0[:,0]) if (em>coords[2] and em<coords[3])]

scale = int(dd/d0) # 0.05 degree -> 0.5 degree
fill_value = -3000
qt = [50,75,95]
for yr in range(2010,2017):
    for mon in range(1,13):
        print([yr,mon])
        A = np.concatenate([xx1d,yy1d,np.tile(yr,(N,1)),np.tile(mon,(N,1))],axis=1)
        yday = datetime(yr,mon,1).timetuple()[7] 
        prefix = inpath+"MYD13C2.A"
        fname = glob.glob(prefix+str(yr)+str(yday).zfill(3)+".006."+"*.hdf")[0]
        file = SD(fname, SDC.READ)
        sds_obj = file.select('CMG 0.05 Deg Monthly NDVI') # select sds
        data = sds_obj.get() # get sds data
        subdata = data[min(idy):max(idy)+1,min(idx):max(idx)+1]
        for q in qt:
            data_upscale = np.reshape(upscale(subdata,scale,fill_value,q),[N,1]).astype(int)
            A = np.concatenate([A,data_upscale],axis=1)
        A = A[A[:,4]>0,:]
        with open('../Data/NDVI.txt','ab') as f:
            np.savetxt(f,A,fmt=['%.2f','%.2f','%4d','%2d','%4d','%4d','%4d'])

#%%
#inpath = "I:/Data/NDVI/"
#file_name = 'MYD13C2.A2010001.006.2015201154556.hdf'
#file = SD(inpath+file_name, SDC.READ)
#
#datasets_dic = file.datasets()
#for idx,sds in enumerate(datasets_dic.keys()):print(idx,sds)
#sds_obj = file.select('CMG 0.05 Deg Monthly NDVI') # select sds
#data = sds_obj.get() # get sds data
#pprint.pprint(sds_obj.attributes() )
#plt.imshow(data)

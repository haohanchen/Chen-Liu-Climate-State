# An example to rasterize shapefile and resample rasster

import numpy as np
from osgeo import gdal,ogr

#%%
scale = 32 # ~ 1 km / 30 m    
for yr in range(2001,2009):
    print(yr)
    inpath = "F:/ForestSurvey/Fires/"
    if yr<2009:
        inname = 'mcd14ml_'+str(yr)+'_005_01_conus'
    else:
        if np.mod(yr,4)==0: inname = 'modis_fire_'+str(yr)+'_366_conus'
        else: inname = 'modis_fire_'+str(yr)+'_365_conus'
    outname = 'modis_fire_'+str(yr)
    vector_fn = inpath+inname+'.shp'
    raster_fn = inpath+'Raster/'+outname+'.tif'
    NoData_value = 0
    pixelWidth = 0.5/1856*scale
    source_ds = ogr.Open(vector_fn)
    source_layer = source_ds.GetLayer()
    xOrigin = -124.5; yOrigin = 42.5
    xcount = int((16+1)*1856/scale)
    ycount = int((19+1)*1856/scale)
    target_ds = gdal.GetDriverByName('GTiff').Create(raster_fn, xcount, ycount, 1, gdal.GDT_Int16)
    target_ds.SetGeoTransform((xOrigin, pixelWidth, 0, yOrigin, 0, -pixelWidth))
    band = target_ds.GetRasterBand(1)
    band.SetNoDataValue(NoData_value)
    
    gdal.RasterizeLayer(target_ds,[1],source_layer,
                        options = ["BURN_VALUE_FROM=Z","ATTRIBUTE=JULIAN"])
    del target_ds
    
    roi_ds = gdal.Open(raster_fn, gdal.GA_ReadOnly)
    roi = roi_ds.GetRasterBand(1).ReadAsArray(0, 0, xcount, ycount).astype(np.int16)
    np.save(inpath+'Raster/'+outname+'.npy',roi)


#%%
import matplotlib.pyplot as plt
del roi
roi = np.load(inpath+'Raster/'+outname+'.npy')
plt.imshow(roi)
#%%
import scipy.ndimage
res_roi = scipy.ndimage.zoom(roi, scale, order=0) # nearest interpolation
res_roi.shape

#%%

nn = int(1856/scale)
tmp = roi[9*nn:10*nn,8*nn:9*nn]
plt.imshow(scipy.ndimage.zoom(tmp, scale, order=0))
plt.figure()
plt.imshow(res_roi[9*1856:10*1856,8*1856:9*1856])
#%%
##from datetime import datetime
#for yr in [2003]:#range(2001,2009):
#    print(yr)
#    inpath = "F:/ForestSurvey/Fires/"
##    if np.mod(yr,4)==0: inname = 'modis_fire_'+str(yr)+'_366_conus'
##    else: inname = 'modis_fire_'+str(yr)+'_365_conus'
#    inname = 'mcd14ml_'+str(yr)+'_005_01_conus'
##    outname = 'modis_fire_'+str(yr)
#    vector_fn = inpath+inname+'.shp'
#    source_ds = ogr.Open(vector_fn,1)
#    source_layer = source_ds.GetLayer()
##    newField = ogr.FieldDefn("JULIAN", ogr.OFTInteger)
##    source_layer.CreateField(newField)
#    for feature in source_layer:
#        jday = feature.GetField("JULIAN")
###        feature.SetField("JULIAN", int(np.mod(jday,yr*1000)))
##        type(jday)
#        print(jday)
##        jday = feature.GetField("JULIAN")
##        feature.SetField("MONTH", int(datetime.strptime(str(jday),'%j').month))
    
    
##%%
#layerDefinition = source_layer.GetLayerDefn()
##
#for i in range(layerDefinition.GetFieldCount()):
#    fieldName =  layerDefinition.GetFieldDefn(i).GetName()
#    fieldTypeCode = layerDefinition.GetFieldDefn(i).GetType()
#    fieldType = layerDefinition.GetFieldDefn(i).GetFieldTypeName(fieldTypeCode)
#    fieldWidth = layerDefinition.GetFieldDefn(i).GetWidth()
#    GetPrecision = layerDefinition.GetFieldDefn(i).GetPrecision()
#    print(fieldName + " - " + fieldType+ " " + str(fieldWidth) + " " + str(GetPrecision))
#%%

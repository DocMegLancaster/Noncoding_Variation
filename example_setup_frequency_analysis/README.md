# Setup Instructions

**1. Create a Google Cloud Storage Bucket**
Create a Google Cloud Storage Bucket. I called mine "bucket_for_storage_across_apps". You can create a storage bucket by, in Verily, going to Resources --> New resource --> New Cloud Storage bucket.

**2. Create a Spark Cluster and Run bag3_to_vcf**
Create a new Spark cluster for your AoU app instance, and under Compute options, under Software to install, select Hail. In this app instance, run bag3_to_vcf.ipynb. Make sure to change the region defined in cell 4 to your own locus.

**3. Create Your Cohorts**
Create your general population control and alternate cohorts, making sure to specify that short read WGS must be included for both cohorts.

**4. Create a Jupyter App Instance**
Create a new app instance, AoU Jupyter (NOT Spark cluster), and under Compute options, select a Machine type that has at least 16 cores. Once the app has been created, run retrieving_vcf_and_tbi.ipynb within it. Then, import variant_population_frequencies.ipynb within this same app instance, but don't run it just yet.

**5. Populate the Query Cells and Run**
For the first two cells in this file, you will need to copy and paste your SQL query code for your two cohorts. To do this, go to Resources, then your cohort, Save data snapshot, then Next (to go to Select file format), and then click the "Copy code" button next to the "Queries for the cohort (IPYNB) with Jupyter Notebook" option. Then paste this code in the first cell for your disease cohort. I have this dataframe variable renamed to cardiomyo_df (I believe the default name it loads as is person_df). Then, in the second cell, do the same thing but for your control cohort. I have mine renamed to generalpop_df. Then, in the final cell, you must define variants that fall within the genomic region you identified in step 2.

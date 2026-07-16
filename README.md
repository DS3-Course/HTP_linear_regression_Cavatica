# R-based analysis of INCLUDE data on Cavatica

## Creating a Cavatica Project  
#### Location: [Cavatica](https://cavatica.sbgenomics.com/) (must be logged in)  
1. Go to *Projects* tab > Create a project.
2. Enter a project name.
3. On <ins>General information</ins> tab:  
   Set Billing group (e.g. Pilot Funds, DS3_2026) and Location (e.g. AWS (us-east-1).  
   Select 'Spot Instances' if desired. 
4. On <ins>Advanced settings</ins> tab:  
   Select 'Allow network access'.  
>[!IMPORTANT]
>If you do not allow network access you will be unable to install R packages or clone the code repository.  
5. Click Create.
6. You should then be taken to the Dashboard for your new project.  
   You may want to edit the project description.  


## 'Pushing' data from the INCLUDE Data Hub to Cavatica  
#### Location: [INCLUDE Data Hub](https://portal.includedcc.org/) (must be logged in)  
1. Connect your INCLUDE and Cavatica accounts  
Within the Data Hub, ensure you are (still) connected to Cavatica:   
Dashboard > Cavatica Projects > Connect. 
>[!IMPORTANT]
>You will need to have two-factor authentication enabled for your Cavatica account or you will get an error at this point.  
2. For this example, filter to HTP MSD data files (n = 477).  
   Data Exploration > Participant > Study Code = HTP.  
   Data Exploration > Biospecimen > Sample Type = Plasma.  
   Data Exploration > Data File > Experimental Strategy = Multiplex Immunoassay.  
   May want to save Filter...  
3. Go to the <ins>*Data Files*</ins> tab: Select all files that you want to analyze (should be 477).  
4. Click on the *Analyse in Cavatica* button.  
   Select the Cavatica Project to which you want to copy files.  
   Click on *Copy files*.  

#### Location: [Cavatica](https://cavatica.sbgenomics.com/)  
>[!IMPORTANT]
>Within Cavatica, ensure you are (still) connected to the INCLUDE Data Hub:  
>Account Settings > Dataset Access > INCLUDE DRS Server > Connect / Reconnect.  

5. Go to the project to which you copied the files.  
   The copied files should now be available in the <ins>*Files*</ins> tab.  

## Running an analysis in Cavatica using 'Data Studio'
#### Location: [Cavatica](https://cavatica.sbgenomics.com/)  
1. Start an *Analysis* instance.  

   a. New *Analysis*:  
      - Go to the <ins>*Data Studio*</ins> tab > Create new analysis.  
      - Set analysis name (e.g. "HTP linear regression").  
      - Select RStudio as your 'Environment' (JupyterLab is also available).  
      - Select latest R version in 'Environment setup' (eg R 4.4.0 - BioC 3.19).  
      - Select Instance type, Attached Storage, Suspend Time (may affect cost).  
      - Click on Start and wait for instance to initialize.  

   b. Existing *Analysis*:  

      - Go to *Data Studio* tab.  
      - Click on Start and wait for instance to initialize (may take several minutes).  

2. You should now be presented with an RStudio instance.  

   a. To create a new Project by cloning from Github. 
    
      - Go to File > New Project... > Version Control > Git.  
      - Enter Repository URL.  
      - May want to modify Project directory name.  
      - Click on Create Project.  
      - May need to enter Github Username and PAT.  
      - Once project opens in RStudio, in R console run `renv::init()` to initialize project and install required packages (renv should already be available).  

   b. Previously created *Analyses* should resume with R Project already open in RStudio.  

      - If not, go to File > Open Project... > Select .Rproj file.  
      - Once project opens in RStudio, in R console run `renv::restore()` to restore project and re-install required packages.  

3. Open analysis R script(s) and work as usual. 


4. Copy R Project to `/sbgenomics/output-files/` for later access/download (see notes below).  

> [!TIP]
> ## Working with RStudio sessions in Data Studio
>* Once Data Studio instances are terminated, after idle timeout or manually, the R environment does not persist (including any newly installed R packages).
>  However, running `renv::restore()` will reinstall packages from local project cache based on `renv.lock` file.  
>
>* Data Studio working dir is:  
>  `/sbgenomics/workspace`  
>  R Project working directory will usually be:  
>  `/sbgenomics/workspace/<R_PROJECT_NAME>`  
>  Files in these directories can be previewed, but not accessed, by clicking on the *Analysis Name* in the *Data Studio* tab.
>
>* Cavatica Project *Files* (eg files transferred from INCLUDE Data Hub) can be accessed here:  
>  `/sbgenomics/project-files`  
>  This directory is read-only from within Data Studio
>
>* To be accessible outside Data Studio, via the *Files* tab in your Cavatica Project, files will need to be copied to: 
>  `/sbgenomics/output-files/`  
>  Any files or dirs copied to this location **will not be accessible until after the Data Studio instance is terminated**.  
>  Saving of these files upon termination ~~may~~ will take several minutes.
>
>* How to get sample metadata:  
<!-- NEED TO ADD DETAILS ABOUT HOW TO GET METADATA DIRECTLY FROM FILES IN CAVATICA - Sex is missing? -->
>  **Option 1**:  
>    In your Cavatica project, go to the <ins>*Files*</ins> tab, select the appropriate files, then click '...' (More actions) and select 'Generate metadata manifest (CSV or TSV)'.  
>    A new manifest file containing metadata will appear in your files list.  
>  **Option 2**:  
>    On the INCLUDE Data hub, once you have selected data files, click on the *Manifest* button on the <ins>*Data Files*</ins> tab: Select all files that you want to analyze, and download the resulting file.  
>    Next, go to the <ins>*Participants*</ins> tab: Select all Participants and click on the *Download clinical data* button, and download the resulting file.  
>    Finally, upload these files to your Cavatica project.





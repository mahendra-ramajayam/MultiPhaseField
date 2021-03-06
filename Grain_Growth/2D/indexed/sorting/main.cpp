// <source lang=cpp>

// 2D simulation with indexed algorithm
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <math.h>
#include <time.h>
#include <algorithm>

// #include <pngwriter.h>

#include "peribc.cpp"
#include "GrainsStat.cpp"
#include "sorting.cpp"
#include "sortp.cpp"
//#include "WriteResults.h"

using namespace std;
int peribc();
int WriteResults();
double GrainsStat();

double sign(double x){
  if (x>0){return 1;}
  if (x<0){return -1;}
  if (x==0){return 0;}
  return 0;
}

// ------- main routin --------
int* MGsize;
int main(int a, char** charinput)
{
  char* dirstr;
  dirstr=charinput[1];
  cout <<"Data will be saved in this Directory:---->" << dirstr <<endl;
  
  bool fullwrite=true;
  // model parameters
  double delt=0.1;
  int timesteps1=201;
  int timesteps=40001;
  int writingtimesteps=500;
  double L=1;
  double m=1.0;
  double gamma=2*1.5*m;
  double kappa=2.0;
  double Pz;
  Pz=double(atoi(charinput[2]))/1000;
  cout << "The friction force is = " << Pz <<"  ----" <<endl;
  double Lf=L, pzi;
  int i,j,tn;
  
  // geometry settings
  int scale=1;
  int mboxsize=30*scale; // x axis in pixels
  int nboxsize=30*scale; // y axis
  double delx=2/scale;      // length unit per pixel
  int p=2; // depth of indexed matrix. 6 should be more than enough for 3D system since quadrouple points have 4 order parameters in common.
  double thresh=0.0000001; //threshold value for choosing active nodes
  double *eta;
  eta= new double[mboxsize*nboxsize*p];
  double *eta2;
  eta2= new double[mboxsize*nboxsize*p];
  int *inds;
  inds= new int[mboxsize*nboxsize*p];
  int *inds2;
  inds2= new int[mboxsize*nboxsize*p];
  
  bool* mbool;
  mbool= new bool[mboxsize*nboxsize];
  double phii;
  double* phi;
  if (fullwrite==true)
  {
    phi= new double[mboxsize*nboxsize];
  }
  int* Maxindfield;
  Maxindfield= new int[mboxsize*nboxsize];
  double meanG;
  // number of nucleas at the beginning of simulation
  int nuclein;
  nuclein=int(mboxsize*nboxsize/200); // ~1 percent of grid points are nuclei
  nuclein=2;
  int nn,ii,jj,pp,pos;
  double irand,jrand,prand;
  
  MGsize=new int[nuclein];
  
//   for (nn=1;nn<nuclein+1;nn++){
 nn=100;   
 irand=rand();
    jrand=rand();
    prand=rand();
    ii=0; //int((nboxsize*irand)/RAND_MAX);
    jj=2; //int((mboxsize*jrand)/RAND_MAX);
    pp=0;//int(p*prand/RAND_MAX)*mboxsize*nboxsize;
    eta[ii+jj*mboxsize+pp]=1;
    inds[ii+jj*mboxsize+pp]=nn;
    inds[peribc(ii+1,mboxsize)+jj*mboxsize+pp]=nn;
    inds[peribc(ii-1,mboxsize)+jj*mboxsize+pp]=nn;
    inds[ii+peribc(jj+1,nboxsize)*mboxsize+pp]=nn;
    inds[ii+peribc(jj-1,nboxsize)*mboxsize+pp]=nn;
//   }
   nn=200;
    ii=15; //int((nboxsize*irand)/RAND_MAX);
    jj=2; //int((mboxsize*jrand)/RAND_MAX);
    pp=0;//int(p*prand/RAND_MAX)*mboxsize*nboxsize;
    eta[ii+jj*mboxsize+pp]=1;
    inds[ii+jj*mboxsize+pp]=nn;
    inds[peribc(ii+1,mboxsize)+jj*mboxsize+pp]=nn;
    inds[peribc(ii-1,mboxsize)+jj*mboxsize+pp]=nn;
    inds[ii+peribc(jj+1,nboxsize)*mboxsize+pp]=nn;
    inds[ii+peribc(jj-1,nboxsize)*mboxsize+pp]=nn;


// particles distribution specification
  /* double diameter=2;
  double particles_fraction=0.00;
  double particlesn=particles_fraction*mboxsize*nboxsize/diameter^2   //
  particles number
  double ppf[nboxsize][mboxsize]
  here goes the function to make particle distribution 
  */
  //dynamics
  double sumterm,currenteta;
  double detadtM;
  double detadt;
  int pn,psn,pind;
  double delx2=1/(delx*delx);
  int size2=mboxsize*nboxsize;
  int jn, pnn;
  int inplus1, inminus1, jnplus1,jnminus1;
  double del2;
  double sumeta, mineta, sumeta2;
  int currentind, indc, indscn,indsc,nc=0,ni,nj,njj;
  double* neighboretas;
  neighboretas=new double[9*p];
  int* neighborinds;
  neighborinds=new int[9*p]; //hold value of indexed at each point and neighbors
  int* maxinds;
  maxinds=new int[10]; //at each point and neighbots it holds index of big etas
  double* maxetas;
  maxetas=new double[10];
  int indsnum=0; //number of distinct order parameters to be calculated in each point
  //calculating processing time
  clock_t time1;
  time1=clock();
  cout << "Initialization ended." <<endl;
  for (tn=1;tn<timesteps1;tn++)
  {
    #pragma omp parallel for
    for (j=0;j<nboxsize;j++)
    {
      jn=j*mboxsize;
      jnplus1=peribc(j+1,nboxsize)*mboxsize;
      jnminus1=peribc(j-1,nboxsize)*mboxsize;
      for (i=0;i<mboxsize;i++)
      {
        mbool[i+jn]=false; //firts we make is false and then if detadt>thresh then it becomes true later
        inplus1=peribc(i+1,mboxsize);
        inminus1=peribc(i-1,mboxsize);
        // here is the sum of all order parameters^2 for the point i and j
        sumterm=0;
        for (psn=0;psn<p;psn++)
        {
          sumterm=sumterm+eta[i+jn+psn*size2]*eta[i+jn+psn*size2];
        }
        //collecting eta and inds from all the neighbors
        nc=0;
        for (pn=0;pn<p;pn++) 
        {
          pnn=pn*size2;
          for (nj=-1;nj<2;nj++)
          {
            njj=peribc(j+nj,nboxsize)*mboxsize;
            for (ni=-1;ni<2;ni++)
            {
              neighboretas[nc]=eta[peribc(i+ni,mboxsize)+njj+pnn];
              neighborinds[nc]=inds[peribc(i+ni,mboxsize)+njj+pnn];
              nc=nc+1;
            }
          }
        }
        //finding 10 largest order parameter (maxinds) within neighbors to do calculation on only those order parameters
        indsnum=sorting(neighboretas,neighborinds,maxinds,p);
        for (indsc=0;indsc<indsnum;indsc++) //counter over imortant eta indexes
        {
          currentind=maxinds[indsc];
          currenteta=0;
          for (indc=0;indc<p;indc++) //find if there is a same eta in the point (i,j)
          {
            indscn=indc*size2;
            if (currentind==inds[i+jn+indscn]){currenteta=eta[i+jn+indscn];}
          }
          //searching for neighbors with the same index as currentind
          sumeta=0;
          for (indc=0;indc<p;indc++)
          {
            indscn=indc*size2;
            if(currentind==inds[inplus1+jn+indscn]){sumeta=sumeta+eta[inplus1+jn+indc*size2];}
            if(currentind==inds[inminus1+jn+indscn]){sumeta=sumeta+eta[inminus1+jn+indc*size2];}
            if(currentind==inds[i+jnplus1+indscn]){sumeta=sumeta+eta[i+jnplus1+indc*size2];}
            if(currentind==inds[i+jnminus1+indscn]){sumeta=sumeta+eta[i+jnminus1+indc*size2];}
          }
          sumeta2=0;
          for (indc=0;indc<p;indc++)
          {
            indscn=indc*size2;
            if(currentind==inds[inplus1+jnplus1+indscn]){sumeta2=sumeta2+eta[inplus1+jnplus1+indc*size2];}
            if(currentind==inds[inminus1+jnminus1+indscn]){sumeta2=sumeta2+eta[inminus1+jnminus1+indc*size2];}
            if(currentind==inds[inminus1+jnplus1+indscn]){sumeta2=sumeta2+eta[inminus1+jnplus1+indc*size2];}
            if(currentind==inds[inplus1+jnminus1+indscn]){sumeta2=sumeta2+eta[inplus1+jnminus1+indc*size2];}
          }
          del2=delx2*(sumeta+0.25*sumeta2-5*currenteta);
          detadtM=m*(currenteta*currenteta*currenteta-currenteta)-kappa*del2;
          detadt=-L*(detadtM+gamma*(currenteta*sumterm-currenteta*currenteta*currenteta));
          maxetas[indsc]=currenteta+delt*detadt;
          // to make sure eta is not outside the equilibrium values. This increases stability of calculation by controlling bounds of the eta whithin equilibrium values
          if (maxetas[indsc]>1) maxetas[indsc]=1;
          if (maxetas[indsc]<0) maxetas[indsc]=0;
        }
        //choose p bigest eta from etalist and assign it to the eta2 matrix
        sortp(maxetas,maxinds,eta2,inds2,size2,p,i,jn);
      }
    }
    //setting eta equal to the new eta2 for the next time step
    #pragma omp parallel for
    for (pind=0;pind<p;pind++)
    {
      pnn=pind*size2;
      for (j=0;j<nboxsize;j++)
      {
        jn=j*mboxsize;
        for (i=0;i<mboxsize;i++)
        {
          eta[i+jn+pnn]=eta2[i+jn+pnn];
        }
      }
    }
    #pragma omp parallel for
    for (pind=0;pind<p;pind++)
    {
      pnn=pind*size2;
      for (j=0;j<nboxsize;j++)
      {
        jn=j*mboxsize;
        for (i=0;i<mboxsize;i++)
        {
          inds[i+jn+pnn]=inds2[i+jn+pnn];
        }
      }
    }    
    
    if (tn % 1==0)
    {
      // making the phi array
      for (j=0;j<nboxsize;j++)
      {
        jn=j*mboxsize;
        for (i=0;i<mboxsize;i++)
        {
          phi[i+jn]=0;
          for (pind=0;pind<p;pind++)
          {
            pnn=pind*size2;
            phi[i+jn]=phi[i+jn]+eta[i+jn+pnn]*eta[i+jn+pnn];
          }
        }
      }
      char filename[200];
      ofstream myfile2;
      // make a string like "result_5.txt"
      sprintf (filename, "%sFullres_%d.txt",dirstr, tn);
      myfile2.open (filename);
      for (j=0;j<nboxsize;j++)
      {
        jn=j*mboxsize;
        for (i=0;i<mboxsize;i++)
        {
          myfile2 << inds[i+jn+1*size2] << "   "; 
        }
        myfile2 << endl;
      }
      myfile2.close();
    }
    
    cout <<tn <<endl;
  }
  
  cout << "time required for 'timesteps1' time steps:" << double((clock()-time1))/double(CLOCKS_PER_SEC) << "seconds. \n";
  time1=clock();
  
  return 0;
}


// </source>

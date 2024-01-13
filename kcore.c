
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
//#include <cuda.h>
#define BLOCK_SIZE 256

struct Triple {
    int first;
    int second;
    int third;
};

int degree(int *row, int i)
{
    int d=row[i+1]-row[i];
    return d;
}

void remove_node(int *row_ptr, int *col_idx, int temp, int *E, int *N, int i)
{
	int start = row_ptr[temp];
	
	while (start < *E && col_idx[start] != i) 
	{
        	start++;
    	}
    	
    	if (start < *E) 
    	{
		for (int l = start; l <= *E - 1; l++) 
		{
		    col_idx[l] = col_idx[l + 1];
		}

	
		for (int l = temp + 1; l <= *N; l++) 
		{
		    row_ptr[l]--;
		}
       
		(*E)--;
		//(*E)--;
    	}
}

int main()
{
    int E, N;
    /*printf("nodes number: ");
    scanf("%d", &N);
    printf("Edge number: ");
    scanf("%d", &E);*/
    
    
    FILE *file = fopen("kcoregraph", "r");
    fscanf(file, "%d", &N);
    fscanf(file, "%d", &E);
    E=2*E;
    
    int *row_ptr = (int *)malloc((N + 2) * sizeof(int));
    int *col_idx = (int *)malloc(E * sizeof(int));
	
	for(int i=0; i<N; i++)
	{
		//printf("%d node ", i);
		fscanf(file, "%d", &row_ptr[i]);	
	}
	
	for(int i=0; i<E; i++)
	{
		//printf("%d col ", i);
		fscanf(file, "%d", &col_idx[i]);	
	}	
	
	row_ptr[N]=E;
	
		
    int k;
    printf("enter core size: ");
    scanf("%d", &k);
    //struct Triple *vec = (struct Triple *)malloc((I) * sizeof(struct Triple));
    int flag=1;
    
    
    while(flag)
    {
    	//printf("helllo \n");
    	flag=0;
      for(int i=0; i<N; i++)
      {
          if(degree(row_ptr, i)<k && col_idx[row_ptr[i]] != -1)
          {
              flag=1;
              //remove node i
                  for(int j=row_ptr[i]; j<row_ptr[i+1]; j++)
                  {
                  	if(col_idx[j] == -1){break;}
                      int temp=col_idx[j];
                      //printf("temp = %d", temp);
                      col_idx[j]=-1;
                      //int t=j;
                      /*while(t<E)
                      {
                      	col_idx[t]=col_idx[t+1];
                      	t++;
                      }*/
                      
                      /*t=i+1;
                      while(t<=N)
                      {
                      	row_ptr[t]--;
                      	t++;
                      }*/
                      //row_ptr[i+1]--;
                      
                      remove_node(row_ptr, col_idx, temp, &E, &N, i);
		      /*for(int i=0; i<=N; i++)
		    	{
				printf("%d\n", row_ptr[i]);
		    	}*/
                      //i--;
                      if(degree(row_ptr,temp)<k)
                      {
                        flag=1;
                        //printf("helllo deg= %d k= %d temp= %d j= %d\n", degree(row_ptr,temp), k, temp, j);
                      }
                  }
             }
             else{flag=0;}

          }
     }
    
    for(int i=0; i<N; i++)
    {
        if(degree(row_ptr, i)>=k)
        {
            printf("%d ", i);
        }
    }

    return 0;



}

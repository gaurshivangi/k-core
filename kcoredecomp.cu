%%cuda
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define BLOCK_SIZE 256

__device__ int degree_d(int *row, int i) {
    return row[i + 1] - row[i];
}



__device__ void remove_node(int *row_ptr, int *col_idx, int *E, int *N, int node, int k) {
    //int tid = threadIdx.x + blockIdx.x * blockDim.x;
    //if (tid < N) {
        int tid=node;
        if (degree_d(row_ptr, tid) < k && col_idx[row_ptr[tid]] != -1) {
            for (int j = row_ptr[tid]; j < row_ptr[tid + 1]; j++) {
                if (col_idx[j] != -1) {
                    int temp = col_idx[j];
                    col_idx[j] = -1;
                    atomicSub(&row_ptr[temp + 1], 1);
                    atomicSub(E, 1);
                    if (degree_d(row_ptr, temp) < k) {
                        *N = temp + 1;
                    }
                }
            }
        }
   // }
}

__device__ void core_check_d(int *row_ptr, int *col_idx, int *deg, int *E, int *N, int node, int k)
{
    remove_node(row_ptr, col_idx, E, N, node, k);
    for(int i=row_ptr[node]; i<row_ptr[node+1]; i++)
    {
        if(degree_d(row_ptr, i)<k)
        {
            core_check_d(row_ptr, col_idx, deg, E, N, i, k);
        }
    }
}

__global__ void core_check(int *row_ptr, int *col_idx, int *deg, int *E, int *N, int k)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x; // Calculate the index of the current thread

    if (idx < *N && degree_d(row_ptr, idx)<k) 
    {
      remove_node(row_ptr, col_idx, E, N, idx, k);
      for(int i=row_ptr[idx]; i<row_ptr[idx+1]; i++)
      {
          if(degree_d(row_ptr, i)<k<k)
          {
              core_check_d(row_ptr, col_idx, deg, E, N, i, k);
          }
      }
    }
}

int main()
{
    int E, N, k;

    FILE *file = fopen("graph2", "r");
    if (file == NULL) {
        fprintf(stderr, "Error opening file\n");
        exit(1);
    }

    fscanf(file, "%d", &N);
    fscanf(file, "%d", &E);
    E = 2 * E;

    int *row_ptr = (int *)malloc((N + 2) * sizeof(int));
    int *col_idx = (int *)malloc(E * sizeof(int));

    for (int i = 0; i <= N; i++) {
        fscanf(file, "%d", &row_ptr[i]);
    }
    int ptr=0;
    E=0;
    while (fscanf(file, "%d", &ptr) != EOF) {
        col_idx[E] = ptr;
        E++;
    }

    //row_ptr[N] = E;
    printf("enter k size: \n");
    scanf("%d", &k);
    
    int deg[N];
    
    for(int i=0; i<N; i++)
    {
        deg[i]=row_ptr[i+1]-row_ptr[i];
    }

    int *d_row_ptr, *d_col_idx, *d_deg, *d_E, *d_N, *d_node, *d_k;
    cudaMalloc((void **)&d_row_ptr, (N + 2) * sizeof(int));
    cudaMalloc((void **)&d_col_idx, E * sizeof(int));
    cudaMalloc((void **)&d_deg, N * sizeof(int));
    cudaMalloc((void **)&d_E, sizeof(int));
    cudaMalloc((void **)&d_N, sizeof(int));
    cudaMalloc((void **)&d_node, sizeof(int));
    cudaMalloc((void **)&d_k, sizeof(int));
    cudaMemcpy(d_row_ptr, row_ptr, (N + 2) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_col_idx, col_idx, E * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_deg, deg, N * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_E, &E, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_N, &N, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_k, &k, sizeof(int), cudaMemcpyHostToDevice);
    /*
    for(int i=0; i<N; i++)
    {
        if(deg[i]<k)
        {
            cudaMemcpy(d_node, &i, sizeof(int), cudaMemcpyHostToDevice);
            core_check<<<1,1>>>(d_row_ptr, d_col_idx, d_deg, d_E, d_N, i, k);
            cudaMemcpy(deg, d_deg, N * sizeof(int), cudaMemcpyDeviceToHost);
        }
    }
    */
   // Launch CUDA kernel
    
    dim3 threadsPerBlock(1024);
    dim3 numBlocks((N + threadsPerBlock.x - 1) / threadsPerBlock.x);
    core_check<<<numBlocks, threadsPerBlock>>>(d_row_ptr, d_col_idx, d_deg, d_E, d_N, k);


    
    for(int i=0; i<N; i++)
    {
        if(deg[i]>=k)
        {printf("%d ", i);}
    }

    free(row_ptr);
    free(col_idx);
    cudaFree(d_row_ptr);
    cudaFree(d_col_idx);
    cudaFree(d_E);
    cudaFree(d_N);
    cudaFree(d_node);
    cudaFree(d_k);
    fclose(file);

    return 0;
}


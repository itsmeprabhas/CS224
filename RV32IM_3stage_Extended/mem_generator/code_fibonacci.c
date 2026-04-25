#include<stdio.h>
int result;

int main(void)
{
  int n=10;   
  int a=0;
  int b=1;
  int i;
  for(i=2;i<=n;i++)
  {
    int c=a+b;
    a=b;
    b=c;
  }
  result=b;
  return 0;
}

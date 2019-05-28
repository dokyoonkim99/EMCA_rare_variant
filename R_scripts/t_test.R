
t.test2 <- function(m1,m2,s1,s2,n1,n2)
{
  se <- sqrt( (1/n1 + 1/n2) * ((n1-1)*s1^2 + (n2-1)*s2^2)/(n1+n2-2) ) 
  df <- n1+n2-2
      
  t <- (m1-m2)/se 
  dat <- c(m1-m2, se, t, 2*pt(-abs(t),df))    
  names(dat) <- c("Difference of means", "Std Error", "t", "p-value")
  return(dat) 
}




# Discovery (phase 1)
# Age
t.test2(60.12, 58.36, 11.69, 14.45, 472, 3888)

# BMI
t.test2(37.83, 31.73, 9.55, 8.12, 472, 3888)

# Replication (phase 2)

# Age
t.test2(60.97, 56.45, 10.51, 14.05, 261, 1531)

# BMI
t.test2(36.56, 31.72, 10.10, 8.07, 261, 1531)


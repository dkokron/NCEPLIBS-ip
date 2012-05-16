 program ipolatev_driver

! interpolate a global lat/lon grid of vector wind to several
! grids of various projections using all ipolatev 
! interpolation options.

 use omp_lib
 use get_input_data

 implicit none

 integer :: tid

!$OMP PARALLEL PRIVATE(TID)
 tid=omp_get_thread_num()
 print*,'- HELLO WORLD FROM THREAD: ',tid
!$OMP END PARALLEL

 call degrib_input_data

 call interp

 print*,"- NORMAL TERMINATION"

 stop
 end program ipolatev_driver

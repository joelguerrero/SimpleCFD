! ers_euler_ideal_1d.f90
!
! Exact Riemann Solver for ideal 1D euler equations, producing a 
! converged exact solution.
! 
! <link to wiki> 

module shared_data ! a common block essentially

  implicit none

  integer, parameter :: num=selected_real_kind(p=6) !p=6 or 15
  integer :: niter !debug

  real(num) :: rhol, ul, pl, rhor, ur, pr !W_l and W_r
  real(num) :: gamma, gm, gp, g1, g2, g3, g4, g5, g6, g7 !gamma + const
  real(num) :: al,ar, bl, br !more constants
  real(num) :: cl, cr !sound speeds
  real(num) :: ps, us, rhosl, rhosr !star region vars

  
  public 

  contains 

  subroutine constants
    !gamma 
    gm = gamma - 1.0_num
    gp = gamma + 1.0_num 
    g1 = gm / 2.0_num / gamma
    g2 = gp / 2.0_num / gamma
    g3 = 2.0_num * gamma / gm
    g4 = 2.0_num / gm
    g5 = 2.0_num / gp
    g6 = gm / gp
    g7 = gm / 2.0_num
    !data dependant constants for finding the root of the "f" function
    al = g5 / rhol !only used in pressure function - move out of shared?
    ar = g5 / rhor
    bl = g6 * pl
    br = g6 * pr
    !sound speeds
    cl = sqrt(gamma * pl /rhol)
    cr = sqrt(gamma * pr / rhor)
  end subroutine constants


end module shared_data

module user

  use shared_data 

  implicit none 

  public 

  contains 

  subroutine initial_conditions

    ! set these for your problem - default is Sod
    rhol = 1.0_num
    ul = 0.0_num
    pl = 1.0_num
    rhor = 0.125_num  
    ur = 0.0_num
    pr = 0.10_num 
    gamma = 1.4_num

  end subroutine initial_conditions
  
  subroutine control
    !stub for setting sampling and output options
  end subroutine 

end module user 

module riemann !subroutines related to calculating star states

  use shared_data

  implicit none

  private 

  public :: check_positivity, pstar, ustar, rhostar, &
    newton_raphson 

  !if when all is said and done there are any vars only used at 
  ! this stage it would be sensible to move here from shared_data

  contains 


  subroutine check_positivity
    !stub
  end subroutine check_positivity

  subroutine pstar
    call guess_ps
    call newton_raphson
  end subroutine pstar

  subroutine ustar
    us = 0.5_num * (ul + ur) + &
      & 0.5_num * (f(ps,rightonly=1) - f(ps,leftonly=1))
  end subroutine ustar
 
  subroutine rhostar
    integer :: i
    real(num) :: ck, pk, prat, rhok
    real(num) :: rhos !temp => rhosl or rhosr

    rhosl = 1e15_num !make errors obvious
    rhosr = 1e15_num
    do i = 0,1
      rhos = 1e15_num
      if (i == 0) then 
        ck = cl
        pk =  pl
        rhok = rhol
        prat = ps / pk
      else 
        ck = cr
        pk = pr
        rhok = rhor
        prat = ps / pk
      endif 
      if (ps > pk) then
        rhos = rhok * ( (prat + g6) / (g6 * prat + 1.0_num) )
      else
        rhos = rhok * prat**(1.0_num/gamma) 
      endif
      if (i == 0) then
        rhosl = rhos
      else
        rhosr = rhos
      endif
    enddo

  end subroutine rhostar
 

  subroutine guess_ps !initial guess on pstar 
    ! in the interests of speed you, can base your guess on the value of
    ! pstar as the  given by an appropriate choice of approximate
    ! R solver. This should mean that the Newton-Raphson iterates in as
    ! few steps as possible. 

    ps = 0.5_num * (pl + pr) ! For now just always use arithmetic mean
          !and see if you get same convergence as in Table 4.2 of Toro
  end subroutine guess_ps
 
  subroutine newton_raphson

    integer :: i 
    real(num) :: pold, delta
    real(num) :: tol = 1.0e-6_num
    real(num) :: rpc  

    i = 0 !need to define these instead of header
    rpc = 1e15_num ! for sake of test module

    do
      if (rpc <= tol) exit !condition on tolerance
      pold = ps 
      delta = f(pold)/fprime(pold)
      ps = pold - delta !f(pold)/fprime(pold)
      rpc = 2.0_num * abs((ps - pold) / (ps + pold)) 
      i = i + 1
      if (ps < 0.0_num) ps = tol !to correct -ve p guesses 
      if (i > 20) print *,'nonconvergence of pstar iteration'
      if (i > 20) exit
    enddo 

    niter = i !for test module
  end subroutine newton_raphson

  real(num) function f(p,leftonly,rightonly) !root function
    real(num), intent(in) :: p
    integer, intent(in), optional :: leftonly, rightonly
    real(num) :: ak,bk, pk, prat, ck
    integer :: i, i0, i1

    f = 0.0_num
    i0 = 0 
    i1 = 1

    if (present(leftonly)) i1 = 0
    if (present(rightonly)) i0 = 1
    if (present(leftonly) .and. present(rightonly)) then
      PRINT *, 'what are you doing!?'
      STOP
    endif

    do i = i0,i1

      if (i == 0) then 
        ak = al
        bk = bl
        ck = cl
        pk =  pl
        prat = p / pk
      else 
        ak = ar
        bk = br
        ck = cr
        pk = pr
        prat = p / pk
      endif 

      if (p > pk) then
        f = f + (p - pk) * sqrt(ak / (p + bk))   
      else 
        f = f + g4 * ck * (prat**g1 - 1.0_num)
      endif

    enddo 

    f = f + (ur - ul)

    return
  end function

  real(num) function fprime(p) ! 1st derivative
    real(num), intent(in) :: p
    real(num) :: ak,bk,ck, pk, rhok, prat
    integer :: i 

    fprime = 0.0_num

    do i = 0,1 

      if (i == 0) then 
        ak = al
        bk = bl
        ck = cl
        pk = pl
        rhok = rhol
        prat = p / pk
      else 
        ak = ar
        bk = br
        ck = cr
        pk = pr
        rhok = rhor
        prat = p / pk
      endif 

      if (p > pk) then
        fprime = fprime + &
          & sqrt(ak / (bk + p)) * (1.0_num - 0.5_num * (p-pk)/(bk+p)) 
      else 
        fprime = fprime + prat**(-g2) / (rhok * ck)
      endif

    enddo 

    return
  end function

end module riemann

module tests !subroutines for automatic testing

  use shared_data
  use riemann 

  implicit none

  logical :: test_star = .true.
  logical :: verbose = .false.

  contains

  subroutine test_starvals
    call test_pstar 
    call test_ustar
    call test_rhostar
    if (test_star) then
      print *, 'passed all comparison tests for star vals'
    else
      print *, 'failed a star test - run with verbose to debug'
    endif 
  end subroutine test_starvals
  subroutine test_pstar !check pstar and iteration info
    logical :: test1 = .true.
    real(num) :: tol = 1e-6_num 
    real(num), dimension(5) :: p_toro
    real(num), dimension(4,5) :: p0_toro
    integer, dimension(4,5) :: i_toro
    integer :: i

    !toro
    p_toro = (/0.30313_num, 0.00189_num, 460.894_num, 46.0950_num, &
      & 1691.64_num /)

    i_toro = reshape( (/3,5,3,5, &
                      1, 8, 8 ,9, &
                      5, 4, 3, 4, &
                      5, 4, 3, 4, &
                      4, 5, 4, 6/), shape(i_toro))!, order = (/2,1/) )
 
    p0_toro = reshape((/0.30677_num, 0.55_num, 0.31527_num, 0.55_num, &
      & 0.00189387344_num, tol, tol, 0.4_num, &
      & 912.449_num, 500.005_num, 464.108_num, 500.005_num, &  
      & 82.9831_num, 50.005_num, 46.4162_num, 50.005_num, &
      & 2322.65_num, 781.353_num, 1241.21_num, 253.494_num/), &
      & shape(p0_toro) )

!    do i=1,5 
!      print *,'i_toro',i_toro(:,i) 
!      print *,'p0_toro',p0_toro(:,i) 
!    enddo

    call test_1 ! initialise  Sods' test
    do i = 1, 4 
      ps = p0_toro(i,1)
      call newton_raphson 
      if (verbose) & 
        & print *, 'test 1: ','p0', p0_toro(i,1), 'ps',ps,'niter',niter
      if (niter .ne. i_toro(i,1)) then
        print *,'fail'
        test1 = .false.
      endif
    enddo     

    call test_2
    do i = 1, 4 
      ps = p0_toro(i,2)
      call newton_raphson 
      if (verbose) & 
        & print *, 'test 2: ','p0', p0_toro(i,2), 'ps',ps,'niter',niter
      if (niter .ne. i_toro(i,2)) print *,'fail'
    enddo     

    call test_3
    do i = 1, 4 
      ps = p0_toro(i,3)
      call newton_raphson 
      if (verbose) & 
        & print *, 'test 3: ','p0', p0_toro(i,3), 'ps',ps,'niter',niter
      if (niter .ne. i_toro(i,3)) print *,'fail'
    enddo     

    call test_4
    do i = 1, 4 
      ps = p0_toro(i,4)
      call newton_raphson 
      if (verbose) & 
        & print *, 'test 4: ','p0', p0_toro(i,4), 'ps',ps,'niter',niter
      if (niter .ne. i_toro(i,4)) print *,'fail'
    enddo     

    call test_5
    do i = 1, 4 
      ps = p0_toro(i,5)
      call newton_raphson 
      if (verbose) & 
        & print *, 'test 5: ','p0', p0_toro(i,5), 'ps',ps,'niter',niter
      if (niter .ne. i_toro(i,5)) print *,'fail'
    enddo     

    if (test1) then 
      print *,'passed pstar test'
    else 
      print *,'failed pstar test'
      test_star = .false.
    endif

  end subroutine test_pstar

  subroutine test_ustar
    real (num) :: diff, utoro
    logical :: test2 = .true.

    call test_1
    call pstar
    call ustar 
    utoro = 0.92745_num 
    diff = 2.0_num * (us - utoro) / (us + utoro)
    if (verbose) print *, 'ustar-test1 and diff',us,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'ustar fail on test1',diff
      test2 = .false. 
    endif

    call test_2
    call pstar
    call ustar 
    utoro =  0.00000_num
    diff = 2.0_num * (us - utoro) / (us + utoro)
    if (verbose) print *, 'ustar-test2 and diff',us,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *, 'ustar fail on test2',diff
      test2 = .false. 
    endif

    call test_3
    call pstar
    call ustar 
    utoro = 19.5975_num
    diff = 2.0_num * (us - utoro) / (us + utoro)
    if (verbose) print *, 'ustar-test3 and diff',us,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *, 'ustar fail on test3',diff
      test2 = .false. 
    endif

    call test_4
    call pstar
    call ustar 
    utoro = -6.19633_num
    diff = 2.0_num * (us - utoro) / (us + utoro)
    if (verbose) print *, 'ustar-test4 and diff',us,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *, 'ustar fail on test4',diff
      test2 = .false. 
    endif

    call test_5
    call pstar
    call ustar 
    utoro = 8.68975_num
    diff = 2.0_num * (us - utoro) / (us + utoro)
    if (verbose) print *, 'ustar-test5 and diff',us,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *, 'ustar fail on test4',diff
      test2 = .false. 
    endif
    

    if (test2) then 
      print *,'passed ustar test'
    else 
      print *,'failed ustar test'
      test_star = .false.
    endif
  end subroutine test_ustar

  subroutine test_rhostar

    real (num) :: diff, ltoro, rtoro
    logical :: test3 = .true.

    call test_1
    call pstar
    call ustar
    call rhostar

    ltoro = 0.42632_num
    diff = rhosl-ltoro
!    diff = 2.0_num * (rhosl - ltoro) / (rhosl + ltoro)
    if (verbose) print *, 'rhostar left-test1 and diff',rhosl,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test1 left'
      test3 = .false. 
    endif

    rtoro = 0.26557_num
    diff = rhosr-rtoro
!   diff = 2.0_num * (rhosr - rtoro) / (rhosr + rtoro)
    if (verbose) print *, 'rhostar right -test1 and diff',rhosr,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test1 right'
      test3 = .false. 
    endif


    call test_2
    call pstar
    call ustar
    call rhostar

    ltoro = 0.02185_num
    diff = rhosl-ltoro
    !diff = 2.0_num * (rhosl - ltoro) / (rhosl + ltoro)
    if (verbose) print *, 'rhostar left-test2 and diff',rhosl,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test2 left'
      test3 = .false. 
    endif

    rtoro = ltoro
    diff = rhosr-rtoro
!    diff = 2.0_num * (rhosr - rtoro) / (rhosr + rtoro)
    if (verbose) print *, 'rhostar right -test2 and diff',rhosr,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test2 right'
      test3 = .false. 
    endif

    call test_3
    call pstar
    call ustar
    call rhostar

    ltoro = 0.57506_num 
    diff = rhosl-ltoro
    !diff = 2.0_num * (rhosl - ltoro) / (rhosl + ltoro)
    if (verbose) print *, 'rhostar left-test3 and diff',rhosl,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test3 left'
      test3 = .false. 
    endif

    rtoro = 5.99924_num
    diff = rhosr-rtoro
!    diff = 2.0_num * (rhosr - rtoro) / (rhosr + rtoro)
    if (verbose) print *, 'rhostar right -test3 and diff',rhosr,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test3 right'
      test3 = .false. 
    endif

    call test_4
    call pstar
    call ustar
    call rhostar

    ltoro = 5.99242_num 
    diff = rhosl-ltoro
    !diff = 2.0_num * (rhosl - ltoro) / (rhosl + ltoro)
    if (verbose) print *, 'rhostar left-test4 and diff',rhosl,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test4 left'
      test3 = .false. 
    endif

    rtoro = 0.57511_num
    diff = rhosr-rtoro
!    diff = 2.0_num * (rhosr - rtoro) / (rhosr + rtoro)
    if (verbose) print *, 'rhostar right -test4 and diff',rhosr,diff
    if (abs(diff) > 5e-6) then
      if (verbose) print *,  'rhostar fail on test4 rightt'
      test3 = .false. 
    endif

    call test_5
    call pstar
    call ustar
    call rhostar

    ltoro = 14.2823_num 
    diff = rhosl-ltoro
    !diff = 2.0_num * (rhosl - ltoro) / (rhosl + ltoro)
    if (verbose) print *, 'rhostar left-test5 and diff',rhosl,diff
    if (abs(diff) > 5e-5) then
      if (verbose) print *,  'rhostar fail on test5 left'
      test3 = .false. 
    endif

    rtoro = 31.0426_num
    diff = rhosr-rtoro
!    diff = 2.0_num * (rhosr - rtoro) / (rhosr + rtoro)
    if (verbose) print *, 'rhostar right -test5 and diff',rhosr,diff
    if (abs(diff) > 5e-5) then !bit higher tol 
      !Toro gives only to certain sf's - by inspection this is 
      !acceptable within roundoff
      if (verbose) print *,  'rhostar fail on test5 right'
      test3 = .false. 
    endif
    if (test3) then 
      print *,'passed rhostar test'
    else 
      print *,'failed rhostar test'
      test_star = .false.
    endif
  endsubroutine test_rhostar

  ! predefined initial conditions

  subroutine test_1 !Sod's test
    rhol = 1.0_num
    ul = 0.0_num
    pl = 1.0_num
    rhor = 0.125_num  
    ur = 0.0_num
    pr = 0.10_num 
    gamma = 1.4_num
    call constants !reset constants
  end subroutine test_1 

  subroutine test_1_r !Reverse Sod's test for symmetry test in p*
    rhor = 1.0_num
    ur = 0.0_num
    pr = 1.0_num
    rhol = 0.125_num !1.0_num / 8.0_num 
    ul = 0.0_num
    pl = 0.10_num 
    gamma = 1.4_num
    call constants !reset constants
  end subroutine test_1_r

  subroutine test_2 !1,2,3 problem
    rhol = 1.0_num
    ul = -2.0_num
    pl = 0.4_num
    rhor = 1.0_num
    ur = 2.0_num
    pr = 0.4_num 
    gamma = 1.4_num
    call constants !reset constants
  end subroutine test_2 

  subroutine test_3 !left half blast
    rhol = 1.0_num
    ul = 0.0_num
    pl = 1000.0_num
    rhor = 1.0_num
    ur = 0.0_num
    pr = 0.01_num
    gamma = 1.4_num
    call constants !reset constants
  end subroutine test_3

  subroutine test_4 !right half
    rhol = 1.0_num
    ul = 0.0_num
    pl = 0.01_num
    rhor = 1.0_num
    ur = 0.0_num
    pr = 100.0_num
    gamma = 1.4_num
    call constants !reset constants
  end subroutine test_4

  subroutine test_5 !both halfs of the W+C blast 
    rhol = 5.99924_num
    ul = 19.5975_num
    pl = 460.894_num
    rhor= 5.99242_num
    ur = -6.19633_num
    pr = 46.0950_num
    gamma = 1.4_num
    call constants !reset constants
  end subroutine 

end module tests

program ers_euler_ideal_1d

  use shared_data
  use riemann 
  use user 
  use tests

  implicit none   

  call test_starvals !check passes all numerical tests

!!!  !do calculations for users setup 
!!!  call initial_conditions
!!!!  call control 
!!!  call constants 
!!!! call check_positivity
!!!
!!!  call pstar
!!!  call ustar
!!!  call rhostar
end program ers_euler_ideal_1d
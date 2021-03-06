module gauss_seidel

  use shared_data
  use boundary_conditions
  use diagnostics
 
  implicit none
 
  private 
 
  public :: solve_const_Helmholtz, &
            solve_variable_elliptic
 
  contains
 
  subroutine solve_const_Helmholtz(phigs,f,alpha,beta,use_old_phi,tol)

    ! Solves the constand co-efficient Helmholtz equation
    ! (alpha - beta del**2) phi = f
    !
    ! For somple Poisson set alpha = 0 and beta = -1 
    ! 
    ! Variable coefficients are handled separately 

    real(num), dimension(-1:nx+2,-1:ny+2), intent(inout) :: phigs
    real(num), dimension(1:nx,1:ny), intent(in) :: f
    real(num), intent(in) :: alpha, beta
    logical, intent(in) :: use_old_phi 
    real(num), intent(in) :: tol

    logical :: gsrb=.true. !hidden option

    real(num) :: L2, L2_old !norms
    real(num) :: L_phigs !laplacian of phigs

    integer :: maxir = -1 ! <0 for no max no of iterations
    integer :: ir = 0 
    logical :: verbose=.false. 
     
     
    print *, '*** begining GS relaxation solve.'
    print *, '*** this can take a while, use VERBOSE if you want to monitor stepping'

    if (.not. use_old_phi) then     
      phi = 0.0_num 
    else 
      call phigs_bcs(phigs) !phi = 0.0_num
    endif 

    L2_old = 1e6_num

    ir = 0
    do
      ir = ir + 1 
     
      ! if not using redblack order
      if (.not. gsrb) then 
        do iy = 1, ny  
        do ix = 1, nx  
          phigs(ix,iy) = phigs(ix+1,iy) + phigs(ix-1,iy) + phigs(ix,iy+1) + phigs(ix,iy-1)
          phigs(ix,iy) = (f(ix,iy) + beta * phigs(ix,iy) / dx**2) / &
            & (alpha + 4.0_num * beta / dx**2)

! hardcoded poisson equation
!          phi(ix,iy) = 0.25_num * ( & 
!            & phi(ix+1,iy) + phi(ix-1,iy) + phi(ix,iy+1) + phi(ix,iy-1) &
!            - dx**2 * divu(ix,iy) ) 
        end do
        end do 
      else !use red black
        ! odd iteration
        do iy = 1, ny  
        do ix = 1, nx  
          if (modulo(ix+iy,2) == 1) then
            phigs(ix,iy) = phigs(ix+1,iy) + phigs(ix-1,iy) + phigs(ix,iy+1) + phigs(ix,iy-1)
            phigs(ix,iy) = (f(ix,iy) + beta * phigs(ix,iy) / dx**2) / &
              & (alpha + 4.0_num * beta / dx**2)



!            phi(ix,iy) = 0.25_num * ( & 
!              & phi(ix+1,iy) + phi(ix-1,iy) + phi(ix,iy+1) + phi(ix,iy-1) &
!              - dx**2 * divu(ix,iy) ) 
          endif
        end do
        end do 
        ! even iteration
        do iy = 1, ny  
        do ix = 1, nx  
          if (modulo(ix+iy,2) == 0) then
            phigs(ix,iy) = phigs(ix+1,iy) + phigs(ix-1,iy) + phigs(ix,iy+1) + phigs(ix,iy-1)
            phigs(ix,iy) = (f(ix,iy) + beta * phigs(ix,iy) / dx**2) / &
              & (alpha + 4.0_num * beta / dx**2)
!            phi(ix,iy) = 0.25_num * ( & 
!              & phi(ix+1,iy) + phi(ix-1,iy) + phi(ix,iy+1) + phi(ix,iy-1) &
!              - dx**2 * divu(ix,iy) ) 
          endif
        end do
        end do 
     
      endif
     
      ! Apply periodic boundary conditions on phi's ghost cells
     
      call phigs_bcs(phigs)
     
      L2 = 0.0_num
      do iy = 1, ny  
      do ix = 1, nx  
        L_phigs = (phigs(ix+1,iy) - 2.0_num*phigs(ix,iy) + phigs(ix-1,iy)) &
          & / dx**2 + & 
          & (phigs(ix,iy+1) - 2.0_num*phigs(ix,iy) + phigs(ix,iy-1)) / dy**2 
     
        !L2 = L2 + abs(divu(ix,iy)-L_phi)**2
        L2 = L2 + abs(f(ix,iy)-(alpha*phigs(ix,iy)-beta*L_phigs))**2
      end do
      end do 
      L2 = sqrt( L2 / REAL(nx*ny,num))
     

      if (verbose) &
        & print *, 'GS-iteration',ir,'complete. L2 is',L2,'|L2-L2_old| is',abs(L2-L2_old),'tol is',tol
     

     !exit conditions 
     !if ((step >= nsteps .and. nsteps >= 0) .or. (L2 <= tol)) exit
     ! alt, exit if the difference between L2 and L2 prev is small - might
     ! indicate convergence
      if ((ir >= maxir .and. maxir >= 0) .or. (abs(L2-L2_old) <= tol)) exit
      L2_old = L2
    end do
     
     
     
    print *, '*** Gauss Seidel relaxation completed in',ir,'steps'
    print *, '*** L2 norm on numerical residuals',L2       

  end subroutine solve_const_Helmholtz

  subroutine solve_variable_elliptic(phigs,f,eta,use_old_phi,tol)


    real(num), dimension(-1:nx+2,-1:ny+2), intent(inout) :: phigs
    real(num), dimension(1:nx,1:ny), intent(in) :: f
    real(num), dimension(0:nx+1,0:ny+1), intent(in) :: eta
            ! ^ eta should typically be rho plus its up-to-date +-1 ghost cells
    logical, intent(in) :: use_old_phi 
    real(num), intent(in) :: tol

    logical :: gsrb=.true. !hidden option

    real(num) :: L2, L2_old !norms
    real(num) :: L_phigs !laplacian of phigs

    real(num) :: eta_ip, eta_im, eta_jp, eta_jm

    integer :: maxir = -1 ! <0 for no max no of iterations
    integer :: ir = 0 
    logical :: verbose=.false. 
     
     
    print *, '*** begining GS relaxation solve.'
    print *, '*** this can take a while, use VERBOSE if you want to monitor stepping'

    if (.not. use_old_phi) then     
      phi = 0.0_num 
    else 
      call phigs_bcs(phigs) !phi = 0.0_num
    endif 

    L2_old = 1e6_num

    ir = 0
    do
      ir = ir + 1 
     
      ! if not using redblack order
      if (.not. gsrb) then 
        do iy = 1, ny  
        do ix = 1, nx  
          !eta_ip actually also has the deltas built in 
          eta_ip = 0.5_num * (eta(ix,iy)+eta(ix+1,iy)) / dx**2
          eta_im = 0.5_num * (eta(ix,iy)+eta(ix-1,iy)) / dx**2
          eta_jp = 0.5_num * (eta(ix,iy)+eta(ix,iy+1)) / dy**2
          eta_jm = 0.5_num * (eta(ix,iy)+eta(ix,iy-1)) / dy**2
       
          phigs(ix,iy) = eta_ip * phigs(ix+1,iy) + eta_im*phigs(ix-1,iy) &
            & + eta_jp * phigs(ix,iy+1) + eta_jm * phigs(ix,iy-1) - f(ix,iy)
          phigs(ix,iy) = phigs(ix,iy) / ( eta_ip + eta_im + eta_jp + eta_jm )
        end do
        end do 
      else !use red black
        ! odd iteration
        do iy = 1, ny  
        do ix = 1, nx  
          if (modulo(ix+iy,2) == 1) then
            !eta_ip actually also has the deltas built in 
            eta_ip = 0.5_num * (eta(ix,iy)+eta(ix+1,iy)) / dx**2
            eta_im = 0.5_num * (eta(ix,iy)+eta(ix-1,iy)) / dx**2
            eta_jp = 0.5_num * (eta(ix,iy)+eta(ix,iy+1)) / dy**2
            eta_jm = 0.5_num * (eta(ix,iy)+eta(ix,iy-1)) / dy**2
       
            phigs(ix,iy) = eta_ip * phigs(ix+1,iy) + eta_im*phigs(ix-1,iy) &
              & + eta_jp * phigs(ix,iy+1) + eta_jm * phigs(ix,iy-1) - f(ix,iy)
            phigs(ix,iy) = phigs(ix,iy) / ( eta_ip + eta_im + eta_jp + eta_jm )
          endif
        end do
        end do 
        ! even iteration
        do iy = 1, ny  
        do ix = 1, nx  
          if (modulo(ix+iy,2) == 0) then
            !eta_ip actually also has the deltas built in 
            eta_ip = 0.5_num * (eta(ix,iy)+eta(ix+1,iy)) / dx**2
            eta_im = 0.5_num * (eta(ix,iy)+eta(ix-1,iy)) / dx**2
            eta_jp = 0.5_num * (eta(ix,iy)+eta(ix,iy+1)) / dy**2
            eta_jm = 0.5_num * (eta(ix,iy)+eta(ix,iy-1)) / dy**2
       
            phigs(ix,iy) = eta_ip * phigs(ix+1,iy) + eta_im*phigs(ix-1,iy) &
              & + eta_jp * phigs(ix,iy+1) + eta_jm * phigs(ix,iy-1) - f(ix,iy)
            phigs(ix,iy) = phigs(ix,iy) / ( eta_ip + eta_im + eta_jp + eta_jm )
          endif
        end do
        end do 
     
      endif
     
      ! Apply periodic boundary conditions on phi's ghost cells
     
      call phigs_bcs(phigs)
     
      L2 = 0.0_num
      do iy = 1, ny  
      do ix = 1, nx  

        eta_ip = 0.5_num * (eta(ix,iy)+eta(ix+1,iy))
        eta_im = 0.5_num * (eta(ix,iy)+eta(ix-1,iy))
        eta_jp = 0.5_num * (eta(ix,iy)+eta(ix,iy+1))
        eta_jm = 0.5_num * (eta(ix,iy)+eta(ix,iy-1))
 
        L_phigs = ( eta_ip * (phigs(ix+1,iy)-phigs(ix,iy)) &
              &    -  eta_im * (phigs(ix,iy)-phigs(ix-1,iy)) ) / dx**2 + & 
              & ( eta_jp * (phigs(ix,iy+1)-phigs(ix,iy)) &
              &    -  eta_jm * (phigs(ix,iy)-phigs(ix,iy-1)) ) / dy**2  

        !residual
        L2 = L2 + abs(f(ix,iy)-L_phigs)**2
      end do
      end do 
      L2 = sqrt( L2 / REAL(nx*ny,num))
     

      if (verbose) &
        & print *, 'GS-iteration',ir,'complete. L2 is',L2,'|L2-L2_old| is',abs(L2-L2_old),'tol is',tol
     

     !exit conditions 
     !if ((step >= nsteps .and. nsteps >= 0) .or. (L2 <= tol)) exit
     ! alt, exit if the difference between L2 and L2 prev is small - might
     ! indicate convergence
      if ((ir >= maxir .and. maxir >= 0) .or. (abs(L2-L2_old) <= tol)) exit
      L2_old = L2
    end do
     
     
     
    print *, '*** Gauss Seidel relaxation completed in',ir,'steps'
    print *, '*** L2 norm on numerical residuals',L2       

  end subroutine solve_variable_elliptic

  subroutine phigs_bcs(phigs) 

    real(num), dimension(-1:nx+2,-1:ny+2), intent(inout) :: phigs

    if (bc_xmin == periodic) then
      phigs(0,:) = phigs(nx,:)
      phigs(-1,:) = phigs(nx-1,:)
    endif
    if (bc_xmax == periodic) then
      phigs(nx+1,:) = phigs(1,:)
      phigs(nx+2,:) = phigs(2,:)
    endif
    if (bc_ymin == periodic) then
      phigs(:,0) = phigs(:,ny)
      phigs(:,-1) = phigs(:,ny-1)
    endif
    if (bc_ymax == periodic) then
      phigs(:,ny+1) = phigs(:,1)
      phigs(:,ny+2) = phigs(:,2)
    endif

    ! Zero gradient

    if (bc_xmin == zero_gradient) then
      phigs(0,:) = phigs(1,:)
      phigs(-1,:) = phigs(2,:)
    endif
    if (bc_xmax == zero_gradient) then
      phigs(nx+1,:) = phigs(nx,:)
      phigs(nx+2,:) = phigs(nx-1,:)
    endif
    if (bc_ymin == zero_gradient) then
      phigs(:,0) = phigs(:,1)
      phigs(:,-1) = phigs(:,2)
    endif
    if (bc_ymax == zero_gradient) then
      phigs(:,ny+1) = phigs(:,ny)
      phigs(:,ny+2) = phigs(:,ny-1)
    endif

    ! No slip

!!    if (bc_xmin == no_slip) then
!!      phigs(0,:) = -phigs(1,:)
!!      phigs(-1,:) = -phigs(2,:)
!!    endif
!!    if (bc_xmax == no_slip) then
!!      phigs(nx+1,:) = -phigs(nx,:)
!!      phigs(nx+2,:) = -phigs(nx-1,:)
!!    endif
!!    if (bc_ymin == no_slip) then
!!      phigs(:,0) = -phigs(:,1)
!!      phigs(:,-1) = -phigs(:,2)
!!    endif
!!    if (bc_ymax == no_slip) then
!!      phigs(:,ny+1) = -phigs(:,ny)
!!      phigs(:,ny+2) = -phigs(:,ny-1)
!!    endif
    if (bc_xmin == no_slip) then
      phigs(0,:) = phigs(1,:)
      phigs(-1,:) = phigs(2,:)
    endif
    if (bc_xmax == no_slip) then
      phigs(nx+1,:) = phigs(nx,:)
      phigs(nx+2,:) = phigs(nx-1,:)
    endif
    if (bc_ymin == no_slip) then
      phigs(:,0) = phigs(:,1)
      phigs(:,-1) = phigs(:,2)
    endif
    if (bc_ymax == no_slip) then
      phigs(:,ny+1) = phigs(:,ny)
      phigs(:,ny+2) = phigs(:,ny-1)
    endif

!    !overwrite with experimental no_slip
    ! seems to give large (>0 !) for the grav problem 

!    if (bc_ymin == no_slip) then
!      phigs(:,0) =  phigs(:,1) - (phigs(:,2)-phigs(:,1))
!      phigs(:,-1) = phigs(:,1) - (phigs(:,2)-phigs(:,1))*2.0_num
!    endif
!    if (bc_ymax == no_slip) then
!      phigs(:,ny+1) = phigs(:,ny) + (phigs(:,ny) - phigs(:,ny-1))
!      phigs(:,ny+2) = phigs(:,ny) + (phigs(:,ny) - phigs(:,ny-1))*2.0_num
!    endif

    !duplicate of no_slip for driven
    if (bc_ymax == driven) then
      phigs(:,ny+1) = phigs(:,ny)
      phigs(:,ny+2) = phigs(:,ny-1)
    endif


  end subroutine phigs_bcs

end module gauss_seidel

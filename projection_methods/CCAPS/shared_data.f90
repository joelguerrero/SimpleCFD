module shared_data

  implicit none
  integer :: out_unit = 10
  integer, parameter :: num=selected_real_kind(p=15) 

  ! core solver

  integer :: nx, ny
  integer :: ix, iy
  integer :: step, nsteps

  real(num) :: time = 0.0_num, t_end, dt 
  real(num) :: CFL
  real(num) :: x_min, x_max
  real(num) :: y_min, y_max
  real(num) :: dx, dy

  logical :: use_minmod = .false. 
  logical :: shear_test = .false.
  logical :: minion_test = .false.
  logical :: vortex1_test = .false.
  logical :: drivenlid_test = .false. 

  real(num), dimension(:), allocatable :: xc, xb, yc, yb

  real(num), dimension(:,:), allocatable :: u, v, p
  real(num), dimension(:,:), allocatable :: uhxl, uhxr, vhxl, vhxr
  real(num), dimension(:,:), allocatable :: uhyl, uhyr, vhyl, vhyr

  real(num), dimension(:,:), allocatable :: uha, vha
  real(num), dimension(:,:), allocatable :: uhx, vhx, uhy, vhy


  real(num), dimension(:,:), allocatable :: uxl, uxr, vxl, vxr
  real(num), dimension(:,:), allocatable :: uyl, uyr, vyl, vyr

  real(num), dimension(:,:), allocatable :: ua, va
  real(num), dimension(:,:), allocatable :: macu, macv

  real(num), dimension(:,:), allocatable :: ux, vx, uy, vy !u on x face, v on x face..
  real(num), dimension(:,:), allocatable :: divu ! divergence of MAC, cc

  real(num), dimension(:,:), allocatable :: phi !cc 

  real(num), parameter :: pi = 4.0_num * ATAN(1.0_num)

  real(num), dimension(:,:), allocatable :: ustar, vstar


  real(num), dimension(:,:), allocatable :: gradp_x, gradp_y ! pressure gradient, cc

  ! boundaries

  integer, parameter :: periodic = 0
  integer, parameter :: zero_gradient = 1
  integer, parameter :: no_slip = 2
  integer, parameter :: driven = 3
  

  integer :: bc_xmin , bc_xmax, bc_ymin, bc_ymax

  ! viscosity

  logical :: use_viscosity = .false.
  real(num) :: visc = 0.0_num


end module shared_data

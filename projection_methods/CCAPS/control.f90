module control 

  use shared_data

  implicit none

  private

  public :: user_control

  contains

  subroutine user_control

    x_min = 0.0_num
    x_max = 1.0_num
    y_min = x_min
    y_max = x_max

    nx = 32 
    ny = nx
  
    CFL = 0.5_num ! CFL modifier

    nsteps = 1000
    t_end = 0.5_num

  end subroutine user_control


end module control 

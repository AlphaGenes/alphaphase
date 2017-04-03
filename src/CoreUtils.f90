module CoreUtils
  
contains
  function calculateCores(nSnp, Jump, offset) result(CoreIndex)
    implicit none

    integer, intent(in) :: nSnp, Jump
    logical, intent(in) :: offset
    integer, dimension(:,:), pointer :: CoreIndex

    double precision :: corelength
    integer :: i, nCores, left

    nCores = nSnp / Jump
    corelength = nSnp / nCores
    left = nSnp - nCores * corelength

    if (.not. Offset) then
      allocate(CoreIndex(nCores, 2))
      CoreIndex(1, 1) = 1
      if (left /= 0) then
	CoreIndex(1, 2) = 1 + corelength
      else
	CoreIndex(1, 2) = corelength
      end if
    else
      nCores = nCores + 1
      allocate(CoreIndex(nCores, 2))
      CoreIndex(1, 1) = 1
      if (left /= 0) then
	CoreIndex(1, 2) = 1 + floor(dble(corelength) / 2.0)
      else
	CoreIndex(1, 2) = floor(dble(corelength) / 2.0)
      end if
    end if

    do i = 2, nCores
      CoreIndex(i,1) = CoreIndex(i - 1, 2) + 1
      if (i <= left) then
	CoreIndex(i, 2) = CoreIndex(i - 1, 2) + corelength + 1
      else
	CoreIndex(i, 2) = CoreIndex(i - 1, 2) + corelength
      end if
    end do

    if (Offset) then
      CoreIndex(nCores,2) = nSnp
    end if
  end function CalculateCores

  function CalculateTails(CoreIndex, nSnp, Jump, CoreAndTailLength) result(TailIndex)
    implicit none

    integer, dimension(:,:), intent(in) :: CoreIndex
    integer, intent(in) :: nSnp, Jump, CoreAndTailLength
    integer, dimension(:,:), pointer :: TailIndex

    integer :: ltail, rtail, nCores
    integer :: i

    nCores = size(CoreIndex,1)
    allocate(TailIndex(nCores,2))

    ltail = floor(dble(CoreAndTailLength - Jump) / 2.0)
    rtail = ceiling(dble(CoreAndTailLength - Jump) / 2.0)


    do i = 1, nCores
      TailIndex(i,1) = max(1,CoreIndex(i,1) - ltail)
      TailIndex(i,2) = min(nSnp,CoreIndex(i,2) + rtail)
    end do
  end function CalculateTails
  
  function getCoresFromLibraries(libraries) result(CoreIndex)
    use HaplotypeLibraryDefinition
    
    type(HaplotypeLibrary), dimension(:), intent(in) :: libraries
    integer, dimension(:,:), pointer :: CoreIndex

    integer :: i, start
    
    allocate(CoreIndex(size(libraries),2))
    
    start = 1
    do i = 1, size(libraries)
      CoreIndex(i,1) = start
      start = start + libraries(i)%nSnps
      CoreIndex(i,2) = start - 1
    end do
  end function getCoresFromLibraries
   
end module CoreUtils

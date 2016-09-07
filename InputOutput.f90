#IFDEF _win32
#DEFINE SEP "\"
#DEFINE MKDIR "md "
#DEFINE RMDIR "RMDIR /S "
#else
#DEFINE SEP "/"
#DEFINE MKDIR "mkdir "
#DEFINE RMDIR "rm -r "
#endif

module InputOutput
  implicit none

  integer, parameter, private :: lengan = 20
  
contains

  !subroutine WriteOutResults(phase, allHapAnis, coreIndex, p)
  subroutine WriteOutResults(allCores, coreIndex, p, writeSwappable)
    use Constants
    use PedigreeDefinition
    use CoreDefinition
    
    type(Core), dimension(:), intent(in) :: allCores
    integer, dimension(:,:), intent(in) :: coreIndex
    type(Pedigree), intent(in) :: p
    logical :: writeSwappable
    
    integer(kind=1), dimension(:), allocatable :: tempPhase

    integer :: i, j, k, l, counter, CounterM, CounterP, nAnisG, nSnp, nCores
    integer, allocatable, dimension(:) :: WorkOut
    double precision, allocatable, dimension(:) :: CoreCount
    integer(kind=1), allocatable, dimension(:) :: TempSwap
    character(len=100) :: fmt

    nAnisG = allCores(1)%getNAnisG()
    nCores = size(allCores)
    nSnp = 0
    do i = 1, nCores
      nSnp = nSnp + allCores(i)%getNCoreSnp()
    end do

    open (unit = 15, file = "."//SEP//"PhasingResults"//SEP//"FinalPhase.txt", status = "unknown")
    open (unit = 25, file = "."//SEP//"PhasingResults"//SEP//"CoreIndex.txt", status = "unknown")
    open (unit = 28, file = "."//SEP//"PhasingResults"//SEP//"SnpPhaseRate.txt", status = "unknown")
    open (unit = 30, file = "."//SEP//"PhasingResults"//SEP//"IndivPhaseRate.txt", status = "unknown")
    open (unit = 33, file = "."//SEP//"PhasingResults"//SEP//"FinalHapIndCarry.txt", status = "unknown")
    if (writeSwappable) then
      open (unit = 44, file = "."//SEP//"PhasingResults"//SEP//"SwapPatMat.txt", status = "unknown")
    end if

    allocate(tempPhase(nSnp))
    write(fmt, '(a,i10,a)') '(a20,', nSnp, 'i2)'
    do i = 1, nAnisG
      do j = 1, nCores
	TempPhase(coreIndex(j,1):coreIndex(j,2)) = allCores(j)%getHaplotype(i,1)
      end do
      write(15, fmt) p%getId(i), &
      TempPhase
      do j = 1, nCores
	TempPhase(coreIndex(j,1):coreIndex(j,2)) = allCores(j)%getHaplotype(i,2)
      end do
      write(15, fmt) p%getId(i), &
      TempPhase
    end do
    deallocate(tempPhase)

    do i = 1, nCores
      write (25, *) i, CoreIndex(i,:)
    end do

    do i = 1, nCores
      do j = 1, allCores(i)%getNCoreSnp()
	counter = 0
	do k = 1, nAnisG
	  if ((allCores(i)%getPhase(k, j, 1) == 0).or.(allCores(i)%getPhase(k, j, 1) == 1)) counter = counter + 1
	  if ((allCores(i)%getPhase(k, j, 2) == 0).or.(allCores(i)%getPhase(k, j, 2) == 1)) counter = counter + 1
	end do
	write (28, '(i10,f7.2)') coreIndex(i,1) + j - 1, (100 * (float(counter)/(2 * nAnisG)))
      end do
    end do

    allocate(CoreCount(nCores * 2))
    write(fmt, '(a,i10,a)') '(a20,', nCores*2, 'f7.2)'
    do i = 1, nAnisG
      l = 0
      do j = 1, nCores
	CounterP = allCores(j)%getNCoreSnp() - allCores(j)%hapNumMissing(i,1)
	l = l + 1
	CoreCount(l) = (float(counterP)/allCores(j)%getNCoreSnp()) * 100
	CounterM = allCores(j)%getNCoreSnp() - allCores(j)%hapNumMissing(i,2)
	l = l + 1
	CoreCount(l) = (float(counterM)/allCores(j)%getNCoreSnp()) * 100
      end do
      write (30, fmt) p%getID(i), CoreCount(:)
    end do
    deallocate(CoreCount)

    allocate(WorkOut(nCores * 2))
    write(fmt, '(a,i10,a)') '(a20,', nCores*2, 'i8)'
    do i = 1, nAnisG
      k = 0
      do j = 1, nCores
	k = k + 2
	WorkOut(k - 1) = AllCores(j)%getHapAnis(i,1)
	WorkOut(k) = AllCores(j)%getHapAnis(i,2)
      end do
      write (33, fmt) p%getID(i), WorkOut(:)
    end do
    deallocate(WorkOut)
    
    if (writeSwappable) then
      allocate(TempSwap(nCores))
      write(fmt, '(a,i10,a)') '(a20,', nCores, 'i2)'
      do i = 1, nAnisG
	do j = 1, nCores
	  TempSwap(j) = AllCores(j)%getSwappable(i)
	end do
	write (44, fmt) p%getID(i), TempSwap
      end do
      deallocate(TempSwap)
    end if
      
    
    close(15)
    close(25)
    close(28)
    close(30)
    close(33)
    close(44)

  end subroutine WriteOutResults

  subroutine writeOutCore(c, coreID, coreStart, p, writeSwappable)
    use Constants
    use PedigreeDefinition
    use CoreDefinition
        
    type(Core), intent(in) :: c
    integer, intent(in) :: coreID
    integer, intent(in) :: coreStart
    type(Pedigree), intent(in) :: p
    logical :: writeSwappable
  
    integer :: i, j, k, l, counter, CounterM, CounterP, nAnisG, nSnp
    integer, allocatable, dimension(:) :: WorkOut
    double precision, allocatable, dimension(:) :: CoreCount
    character(len=100) :: fmt
    
    character(:), allocatable :: coreIDtxt
  
    nAnisG = c%getNAnisG()
    nSnp = c%getNCoreSnp()
    
    allocate(WorkOut(2))
    allocate(CoreCount(2))
    
    coreIDtxt = itoa(coreID)
  
    open (unit = 15, file = "."//SEP//"PhasingResults"//SEP//"FinalPhase" // coreIDtxt // ".txt", status = "unknown")
    open (unit = 28, file = "."//SEP//"PhasingResults"//SEP//"SnpPhaseRate" // coreIDtxt // ".txt", status = "unknown")
    open (unit = 30, file = "."//SEP//"PhasingResults"//SEP//"IndivPhaseRate" // coreIDtxt // ".txt", status = "unknown")
    open (unit = 33, file = "."//SEP//"PhasingResults"//SEP//"FinalHapIndCarry" // coreIDtxt // ".txt", status = "unknown")
    if (writeSwappable) then
      open (unit = 44, file = "."//SEP//"PhasingResults"//SEP//"SwapPatMat" // coreIDtxt // ".txt", status = "unknown")
    end if
  
    write(fmt, '(a,i10,a)') '(a20,', c%getNSnp(), 'i2)'
    do i = 1, nAnisG
      write(15, fmt) p%getID(i), &
      c%getHaplotype(i,1)
      write(15, fmt) p%getID(i), &
      c%getHaplotype(i,2)
    end do
  
    do i = 1, nSnp
      counter = 0
      do j = 1, nAnisG
	  if ((c%getPhase(j, i, 1) == 0).or.(c%getPhase(j, i, 1) == 1)) counter = counter + 1
	  if ((c%getPhase(j, i, 2) == 0).or.(c%getPhase(j, i, 2) == 1)) counter = counter + 1
      end do
      write (28, '(i10,f7.2)') i + CoreStart - 1, (100 * (float(counter)/(2 * nAnisG)))
    end do
  
    do i = 1, nAnisG
      CounterP = c%getNCoreSnp() - c%hapNumMissing(i,1)
      CounterM = c%getNCoreSnp() - c%hapNumMissing(i,2)
      CoreCount(1) = (float(counterP)/(nSnp) * 100)
      CoreCount(2) = (float(counterM)/(nSnp) * 100)
      write(30, '(a20,2f7.2)') p%getID(i), CoreCount(:)
    end do
  
    do i = 1, nAnisG
      WorkOut(1) = c%getHapAnis(i, 1)
      WorkOut(2) = c%getHapAnis(i, 2)
      write (33, '(a20,2i8)') p%getID(i), WorkOut(:)
    end do
    
    if (writeSwappable) then
      do i = 1, nAnisG
	write (44, '(a20,i2)') p%getID(i), c%getSwappable(i)
      end do
    end if
    
    close(15)
    close(28)
    close(30)
    close(33)
    if (writeSwappable) then
      close(44)
    end if
  end subroutine writeOutCore
  
  function itoa(i) result(res)
    character(:),allocatable :: res
    integer,intent(in) :: i
    character(range(i)+2) :: tmp
    write(tmp,'(i0)') i
    res = trim(tmp)
  end function
  
  subroutine CombineResults(nAnisG, CoreIndex, p, writeSwappable)
    use Constants
    use PedigreeDefinition
            
    integer, intent(in) :: nAnisG
    integer, dimension(:,:), intent(in) :: CoreIndex
    type(Pedigree) :: p
    logical :: writeSwappable
    
    integer :: nCores
    
    integer, dimension(:), allocatable :: inUnits
    integer :: i, j, coreLength, inUnit
    character(:), allocatable :: coreIDtxt
    integer(kind=1), dimension(:), allocatable :: tempPhase
    integer, dimension(2) :: tempHapInd, tempIndivSwap
    double precision, dimension(2) :: tempIndivPhase
    double precision :: tempSnpPhase
    character(len=20) :: id
    
    nCores = size(CoreIndex,1)

    open (unit = 15, file = "."//SEP//"PhasingResults"//SEP//"FinalPhase.txt", status = "unknown")
    open (unit = 25, file = "."//SEP//"PhasingResults"//SEP//"CoreIndex.txt", status = "unknown")
    open (unit = 28, file = "."//SEP//"PhasingResults"//SEP//"SnpPhaseRate.txt", status = "unknown")
    open (unit = 30, file = "."//SEP//"PhasingResults"//SEP//"IndivPhaseRate.txt", status = "unknown")
    open (unit = 33, file = "."//SEP//"PhasingResults"//SEP//"FinalHapIndCarry.txt", status = "unknown")
    if (writeSwappable) then
      open (unit = 44, file = "."//SEP//"PhasingResults"//SEP//"SwapPatMat.txt", status = "unknown")
    end if

    do i = 1, nCores
      write (25, *) i, CoreIndex(i,:)
    end do
    
    !!! FINAL PHASE !!!
    allocate(inUnits(nCores))
    do i = 1, nCores
      coreIDtxt = itoa(i)
      open (newunit = inUnits(i), file = "."//SEP//"PhasingResults"//SEP//"FinalPhase" // coreIDtxt // ".txt", status = "old")    
    end do
    
    do i = 1, nAnisG * 2
      do j = 1, nCores
	coreLength  = CoreIndex(j,2) - CoreIndex(j,1) + 1
	allocate(tempPhase(coreLength))
	read(inUnits(j),'(a20,' // itoA(coreLength) // 'i2)') id, tempPhase
	if (j == 1) then
	  write(15, '(a20)', advance = 'no') id
	end if
	if (j == nCores) then
	  write(15, '(' // itoA(coreLength) // 'i2)', advance='yes') tempPhase
	else
	  write(15, '(' // itoA(coreLength) // 'i2)', advance='no') tempPhase
	end if
	deallocate(tempPhase)
      end do
    end do
    
    do i = 1, nCores
      close(inUnits(i))
    end do
    
    deallocate(inUnits)
    
    !!! HAPINDCARRY !!!
    allocate(inUnits(nCores))
    do i = 1, nCores
      coreIDtxt = itoa(i)
      open (newunit = inUnits(i), file = "."//SEP//"PhasingResults"//SEP//"FinalHapIndCarry" // coreIDtxt // ".txt", status = "old")
    end do
    
    do i = 1, nAnisG
      do j = 1, nCores
	read(inUnits(j),'(a20,2i8)') id, tempHapInd
	if (j == 1) then
	  write(33, '(a20)', advance = 'no') id
	end if
	if (j == nCores) then
	  write(33, '(2i8)', advance='yes') tempHapInd
	else
	  write(33, '(2i8)', advance='no') tempHapInd
	end if
      end do
    end do
    
    do i = 1, nCores
      close(inUnits(i))
    end do
    
    deallocate(inUnits)
    
    !!! INDIVPHASE !!!
    allocate(inUnits(nCores))
    do i = 1, nCores
      coreIDtxt = itoa(i)
      open (newunit = inUnits(i), file = "."//SEP//"PhasingResults"//SEP//"IndivPhaseRate" // coreIDtxt // ".txt", status = "old")
    end do
    
    do i = 1, nAnisG
      do j = 1, nCores
	read(inUnits(j),'(a20,2f7.2)') id, tempIndivPhase
	if (j == 1) then
	  write(30, '(a20)', advance = 'no') id
	end if
	if (j == nCores) then
	  write(30, '(2f7.2)', advance='yes') tempIndivPhase
	else
	  write(30, '(2f7.2)', advance='no') tempIndivPhase
	end if
      end do
    end do
    
    do i = 1, nCores
      close(inUnits(i))
    end do
    
    deallocate(inUnits)
    
    !!! SNPPHASE !!!
    do i = 1, nCores
      coreLength  = CoreIndex(i,2) - CoreIndex(i,1) + 1
      coreIDtxt = itoa(i)
      open (newunit = inUnit, file = "."//SEP//"PhasingResults"//SEP//"SnpPhaseRate" // coreIDtxt // ".txt", status = "old")
      do j = 1, coreLength
	read(inUnit,'(a10,f7.2)') id, tempSnpPhase
	write(28,'(a10,f7.2)') id, tempSnpPhase
      end do
      close(inUnit)
    end do
 
    !!! SWAPHAPMAT !!!
    if (writeSwappable) then
      allocate(inUnits(nCores))
      do i = 1, nCores
	coreIDtxt = itoa(i)
	open (newunit = inUnits(i), file = "."//SEP//"PhasingResults"//SEP//"SwapPatMat" // coreIDtxt // ".txt", status = "old")
      end do

      do i = 1, nAnisG
	do j = 1, nCores
	  read(inUnits(j),'(a20,2i2)') id, tempIndivSwap
	  if (j == 1) then
	    write(44, '(a20)', advance = 'no') id
	  end if
	  if (j == nCores) then
	    write(44, '(2i2)', advance='yes') tempIndivSwap
	  else
	    write(44, '(2i2)', advance='no') tempIndivSwap
	  end if
	end do
      end do
    
      do i = 1, nCores
	close(inUnits(i))
      end do
    
      deallocate(inUnits)
    end if
    
    close(15)
    close(25)
    close(28)
    close(30)
    close(33)
    if (writeSwappable) then
      close(44)
    end if

  end subroutine CombineResults
  
  function ParsePedigreeData(params) result(p)
    use Constants
    use ParametersDefinition
    use PedigreeDefinition
    use NRMCode
    use Sorting
        
    type(Parameters), intent(in) :: params
    type(Pedigree) :: p
    
    integer :: i, j, k, SumPseudoNrmS, SumPseudoNrmD, truth, counter, CountMissingGenotype, SireGen, DamGen, nAnisG
    real(kind = 4) :: value, valueS, valueD, SumNrm, SumDiag
    integer, allocatable, dimension (:) :: GenoInPed, WorkVec, ReadingVector
    
    integer, allocatable, dimension (:) :: DanRecode, DanPos !, DanDamGenotyped, DanSireGenotyped
    character(lengan), allocatable, dimension(:) :: DanArray
    integer spos, dpos

    integer :: nAnisRawPedigree
    
    ! Removing Pedigree global variable as first step to moving to seperate subroutine
    character(lengan), allocatable :: ped(:,:)
    !character(lengan), allocatable :: Id(:)
    
    integer(kind = 4), allocatable, dimension (:), target :: SireGenotyped, DamGenotyped
    character(lengan), dimension(:), allocatable :: GenotypeId
    
    call CountInData(nAnisRawPedigree, nAnisG, params)

    allocate(GenotypeId(nAnisG))
    allocate(GenoInPed(nAnisG))
!    allocate(RecodeGenotypeId(nAnisG))
    allocate(Ped(nAnisRawPedigree, 3))
    allocate(WorkVec(params%nSnp * 2))
    allocate(ReadingVector(params%nSnp))
    
    if (trim(params%PedigreeFile) /= "NoPedigree") then
      open (unit = 2, file = trim(params%PedigreeFile), status = "old")
      do i = 1, nAnisRawPedigree
	read(2, *) ped(i,:)
      enddo
      close(2)
    else
      open (unit = 3, file = trim(params%GenotypeFile), status = "old")
      do i = 1, nAnisRawPedigree
	ped(i, 2:3) = "0"
	read (3, *) ped(i, 1)
      enddo
      close (3)
    endif

    GenoInPed = 0

    open (unit = 3, file = trim(params%GenotypeFile), status = "old")
    
    allocate(DanArray(size(ped, 1)))
    allocate(DanPos(size(ped,1)))
    DanArray = adjustr(ped(:,1))
    call SortWithIndex(DanArray,DanPos)
    
    do i = 1, nAnisG
      truth = 0
      if (params%GenotypeFileFormat == 1) then
	read (3, *) GenotypeId(i), ReadingVector(:)
      end if
      if (params%GenotypeFileFormat == 2) then
	!read (3, *) GenotypeId(i), Phase(i,:, 1)
	!read (3, *) GenotypeId(i), Phase(i,:, 2)
	read (3, *) GenotypeId(i), ReadingVector(:)
	read (3, *) GenotypeId(i), ReadingVector(:)
      end if
      if (params%GenotypeFileFormat == 3) then
	read (3, *) GenotypeId(i), WorkVec(:)
      endif
!      do j = 1, nAnisRawPedigree
!	if (GenotypeId(i) == ped(j, 1)) then
!	  truth = 1
!	  exit
!	endif
!      enddo
      truth = BinarySearch(DanArray,adjustr(GenotypeID(i)))
      if (truth == 0) GenoInPed(i) = 1
    enddo
    deallocate(Ped)
    deallocate(DanArray)
    deallocate(DanPos)
    
    close(3)

    if (trim(params%PedigreeFile) /= "NoPedigree") then
      nAnisRawPedigree = nAnisRawPedigree + count(GenoInPed(:) == 1)
    else
      nAnisRawPedigree = nAnisG
    endif
    allocate(Ped(nAnisRawPedigree, 3))
    if (trim(params%PedigreeFile) /= "NoPedigree") then
      open (unit = 2, file = trim(params%PedigreeFile), status = "old")
      do i = 1, nAnisRawPedigree - count(GenoInPed(:) == 1)
	read(2, *) ped(i,:)
      end do
      counter = nAnisRawPedigree - count(GenoInPed(:) == 1)
      do i = 1, nAnisG
	if (GenoInPed(i) == 1) then
	  counter = counter + 1
	  ped(counter, 1) = GenotypeId(i)
	  ped(counter, 2) = "0"
	  ped(counter, 3) = "0"
	endif
      enddo
      close(2)
    else
      do i = 1, nAnisG
	ped(i, 1) = GenotypeId(i)
	ped(i, 2) = "0"
	ped(i, 3) = "0"
      enddo

    endif

    allocate(SireGenotyped(nAnisG))
    allocate(DamGenotyped(nAnisG))    
    
!    allocate(DanRecode(size(ped,1)))
!    DanRecode = 0
!    do i = 1, nAnisG
!      do j = 1, size(ped,1)
!	if (ped(j,1) == GenotypeId(i)) then
!	  DanRecode(j) = i
!	  exit
!	end if
!      end do
!    end do
!    
!    allocate(SireGenotyped(nAnisG))
!    allocate(DamGenotyped(nAnisG))
    
!    SireGenotyped = 0
!    DamGenotyped = 0
!    do i = 1, size(ped,1)
!      if (DanRecode(i) /= 0) then
!	do j = 1, nAnisG
!	  if (GenotypeID(j) .eq. ped(i,2)) then
!	    SireGenotyped(DanRecode(i)) = j
!	  end if
!	  if (GenotypeID(j) .eq. ped(i,3)) then
!	    DamGenotyped(DanRecode(i)) = j
!	  end if
!	end do
!      end if
!    end do
!
!    deallocate(DanRecode)
    
    allocate(DanArray(size(GenotypeID)))
    allocate(DanPos(size(GenotypeID)))
    DanArray = adjustr(GenotypeID)
    call SortWithIndex(DanArray,DanPos)
    
    allocate(DanRecode(size(ped,1)))
    do i = 1, size(ped,1)
      dpos = BinarySearch(DanArray, adjustr(ped(i,1)))
      if (dpos > 0) then
	DanRecode(i) = DanPos(dpos)
      else
	DanRecode(i) = 0
      endif
    end do
    
    SireGenotyped = 0
    DamGenotyped = 0
    do i = 1, size(ped,1)
      if (DanRecode(i) /= 0) then
	spos = BinarySearch(DanArray, adjustr(ped(i,2)))
	if (spos > 0) then
	  SireGenotyped(DanRecode(i)) = DanPos(spos)
	endif
	dpos = BinarySearch(DanArray, adjustr(ped(i,3)))
	if (dpos > 0) then
	  DamGenotyped(DanRecode(i)) = DanPos(dpos)
	endif
      end if
    end do

    deallocate(DanArray)
    deallocate(DanRecode)
    deallocate(DanPos)

    allocate (nrmped(size(ped,1),size(ped,2)))
    nrmped = ped
    
    p = Pedigree(sireGenotyped, damGenotyped, genotypeId)
    
    !deallocate(sireGenotyped, damGenotyped, genotypeID)
  end function ParsePedigreeData
  
  function ParseGenotypeData(startSnp, endSnp, nAnisG, params) result(Genos)
    use ParametersDefinition
    use Constants
    
    integer, intent(in) :: startSnp, endSnp, nAnisG
    type(Parameters), intent(in) :: params
    integer(kind=1), allocatable, dimension(:,:) :: Genos

    integer :: i, j, k
    integer, allocatable, dimension (:) :: WorkVec, ReadingVector
    integer :: nReadSnp
    character(lengan) :: dummy
    
    open (unit = 3, file = trim(params%GenotypeFile), status = "old")

    nReadSnp = endSnp - startSnp + 1

    allocate(Genos(nAnisG, nReadSnp))
    Genos = MissingGenotypeCode
    
    !allocate(Phase(nAnisG, nReadSnp, 2))
    allocate(WorkVec(params%nSnp * 2))
    allocate(ReadingVector(params%nSnp))

    !allocate(HapLib(nAnisG * 2, nSnp))

    !Phase = 9

    Genos = MissingGenotypeCode
    do i = 1, nAnisG
      if (params%GenotypeFileFormat == 1) then
	read (3, *) dummy, ReadingVector(:)
	!do j = 1, nSnp
	do j = startSnp, endSnp
	  if ((ReadingVector(j) /= 0).and.(ReadingVector(j) /= 1).and.(ReadingVector(j) /= 2)) ReadingVector(j) = MissingGenotypeCode
	  Genos(i, j - startSnp + 1) = ReadingVector(j)
!	  if (Genos(i, j) == 0) Phase(i, j,:) = 0
!	  if (Genos(i, j) == 2) Phase(i, j,:) = 1
	end do
      end if
!      if (GenotypeFileFormat == 2) then
!	!read (3, *) GenotypeId(i), Phase(i,:, 1)
!	!read (3, *) GenotypeId(i), Phase(i,:, 2)
!	read (3, *) dummy, ReadingVector(:)
!	Phase(i,:,1) = ReadingVector(startSnp:endSnp)
!	read (3, *) dummy, ReadingVector(:)
!	Phase(i,:,2) = ReadingVector(startSnp:endSnp)
!      end if
      if (params%GenotypeFileFormat == 3) then
	read (3, *) dummy, WorkVec(:)
	k = 0
	!do j = 1, nSnp * 2
	do j = startSnp*2-1,endSnp*2
	  if (mod(j, 2) == 0) then
	    k = k + 1
	    if ((WorkVec(j - 1) == 1).and.(WorkVec(j) == 1)) Genos(i, k) = 0
	    if ((WorkVec(j - 1) == 1).and.(WorkVec(j) == 2)) Genos(i, k) = 1
	    if ((WorkVec(j - 1) == 2).and.(WorkVec(j) == 1)) Genos(i, k) = 1
	    if ((WorkVec(j - 1) == 2).and.(WorkVec(j) == 2)) Genos(i, k) = 2
	  endif
	end do
      endif
    enddo
    
    close(3)
  end function ParseGenotypeData
  
  function ParsePhaseData(PhaseFile, startSnp, endSnp, nAnisG, nSnp) result(Phase)
    use Constants
    
    character(len=300) :: PhaseFile
    integer, intent(in) :: startSnp, endSnp, nAnisG, nSnp
    integer(kind=1), allocatable, dimension(:,:,:) :: Phase

    integer :: i, j, k
    integer, allocatable, dimension (:) :: WorkVec, ReadingVector
    integer :: nReadSnp
    character(lengan) :: dummy
    
    open (unit = 3, file = trim(PHaseFile), status = "old")

    nReadSnp = endSnp - startSnp + 1

    allocate(Phase(nAnisG, nReadSnp, 2))
    allocate(ReadingVector(nSnp))

    do i = 1, nAnisG
      read (3, *) dummy, ReadingVector(:)
      Phase(i,:,1) = ReadingVector(startSnp:endSnp)
      read (3, *) dummy, ReadingVector(:)
      Phase(i,:,2) = ReadingVector(startSnp:endSnp)
    enddo
    
    close(3)
  end function ParsePhaseData

  function ReadInParameterFile(filename) result (params)
    use ParametersDefinition
        
    character(*), intent(in) :: filename
    type(Parameters) :: params

    double precision :: PercSurrDisagree
    integer :: i, TempInt, Graphics, status, cl
    character (len = 300) :: dumC, FileFormat, OffsetVariable, hold
    
    params = Parameters()

    !open (unit = 1, file = "AlphaPhaseSpec.txt", status = "old")
    open (unit = 1, file = filename, status = "old")

    read (1, *) dumC, params%PedigreeFile
    read (1, *) dumC, params%GenotypeFile, FileFormat
    if (trim(FileFormat) == 'GenotypeFormat') then
      params%GenotypeFileFormat = 1
    elseif (trim(FileFormat) == 'PhaseFormat') then
      params%GenotypeFileFormat = 2
    elseif (trim(FileFormat) == 'UnorderedFormat') then
      params%GenotypeFileFormat = 3
    else
      print*, "The genotype file format is not correctly specified"
      stop
    endif

    print *, " Parameter file read"
    print *, " "
    print *, " Using ", trim(params%PedigreeFile), " as the pedigree file"
    print *, " Using ", trim(params%GenotypeFile), " as the genotype file"
    print *, " "

    read (1, *) dumC, params%nSnp
    read (1, *) dumC, params%CoreAndTailLength
    if (params%CoreAndTailLength > params%nSnp) then
      print*, "GeneralCoreAndTailLength is too long"
      stop
    endif
    read (1, *) dumC, params%Jump, OffsetVariable
    if (params%Jump > params%nSnp) then
      print*, "GeneralCoreLength is too long"
      stop
    endif

    if (params%CoreAndTailLength < params%Jump) then
      print *, "GeneralCoreAndTailLength is shorted than GenralCoreLength"
      stop
    end if

    if (OffsetVariable == "Offset") then
      params%Offset = .true.
    endif
    if (OffsetVariable == "NotOffset") then
      params%Offset = .false.
    endif

    if ((OffsetVariable /= "Offset").and.(OffsetVariable /= "NotOffset")) then
      print*, "Offset variable is not properly parameterised"
      stop
    endif
    read (1, *) dumC, params%UseSurrsN
    read (1, *) dumC, PercSurrDisagree
    read (1, *) dumC, params%PercGenoHaploDisagree
    read (1, *) dumC, params%GenotypeMissingErrorPercentage
    read (1, *) dumC, params%NrmThresh
    read (1, *) dumC, TempInt
    params%FullFileOutput = (TempInt == 1)
    read (1, *) dumC, Graphics
    read (1, *) dumC, TempInt
    params%Simulation = (TempInt == 1)
    read (1, *) dumC, params%TruePhaseFile

    read (1, *, iostat=status) dumC, tempInt
    if (status == 0) then
      params%readCoreAtTime = (tempInt==1)
    else
      params%readCoreAtTime = .false.
    end if

    read (1, *, iostat=status) dumC, params%itterateType
    if (status == 0) then
      params%consistent = ((params%itterateType .eq. "Off") .and. (.not. params%readCoreAtTime))
    else
      params%consistent = .true.
      params%itterateType = "Off"
    end if

!    read (1, *, iostat=status) dumC, itterateNumber
!    if (status /= 0) then
!      itterateNumber = 200
!    end if
!    read (1, *, iostat=status) dumC, numIter
!    if (status /= 0) then
!      numIter = 1
!    end if
    read(1, *, iostat=status) dumC, hold
    if (status == 0) then
      if (hold(1:1) == "*") then
	read(hold,"(X,I2)") cl
	call get_command_argument(cl,hold)
	read(hold,*) params%itterateNumber
      else
	read(hold,*) params%itterateNumber
      end if
    else
      params%itterateNumber = 200
    end if
    
    read(1, *, iostat=status) dumC, hold
    if (status == 0) then
      if (hold(1:1) == "*") then
	read(hold,"(X,I2)") cl
	call get_command_argument(cl,hold)
	read(hold,*) params%numIter
      else
	read(hold,*) params%numIter
      end if
    else
      params%numIter = 1
    end if
    if (params%itterateType .eq. "Off") then
      params%numIter = 1
    end if

    read (1, *, iostat=status) dumC, params%startCoreChar, params%endCoreChar
    if (status /= 0) then
      params%startCoreChar = "1"
      params%endCoreChar = "Combine"
    end if
    
    read (1, *, iostat=status) dumC, hold
    if (status == 0) then
      if (hold(1:1) == "*") then
	read(hold,"(X,I2)") cl
	call get_command_argument(cl,hold)
	read(hold,*) params%minHapFreq
      else
	read(hold,*) params%minHapFreq
      end if
    else
      params%minHapFreq = 1
    end if
    
    read(1, *, iostat=status) dumC, params%library
    if (status /= 0) then
      params%library = "None"
    end if
    params%consistent = params%consistent .and. (params%library .eq. "None")

    PercSurrDisagree = PercSurrDisagree/100
    params%NumSurrDisagree = int(params%UseSurrsN * PercSurrDisagree)
    params%PercGenoHaploDisagree = params%PercGenoHaploDisagree/100
    params%GenotypeMissingErrorPercentage = params%GenotypeMissingErrorPercentage/100

    close (1)

    if (Graphics == 1) then
      print*, "Graphics option is not yet functional"
      stop
    end if

    !if (nSnp>32767) then
    !        print*, "Kind=2 is not sufficient for this number of SNP.... Contact John Hickey because there is a simple solution!"
    !        stop
    !end if

  end function ReadInParameterFile

  subroutine HapCommonality(library, OutputPoint, params)
    !! This should probably be two routines - one to calculate, one to output
    use Constants
    use HaplotypeLibraryDefinition
    use ParametersDefinition
    
    type(HaplotypeLibrary), intent(in) :: library
    integer, intent(in) :: OutputPoint
    class(Parameters), intent(in) :: params
    
    integer :: i, SizeCore, nHaps
    character(len = 300) :: filout

    integer, allocatable, dimension (:,:) :: HapRel

    SizeCore = library%getNumSnps()
    nHaps = library%getSize()

    if (params%FullFileOutput) then
	write (filout, '(".",a1,"PhasingResults",a1,"HaplotypeLibrary",a1,"Extras",a1,"HapCommonality",i0,".txt")') SEP, SEP, SEP, SEP, OutputPoint
	open (unit = 27, FILE = filout, status = 'unknown')
    endif

    HapRel = library%getHapRel()

    if (params%FullFileOutput) then
      do i = 1, nHaps
	write (27, '(i10,20000F5.2,20000F5.2,20000F5.2,20000F5.2)') i, float(HapRel(i,:))/SizeCore
      enddo
    endif

    close(27)

  end subroutine HapCommonality

  !########################################################################################################################################################################

  subroutine WriteSurrogates(definition, threshold, OutputPoint, p)
    use SurrogateDefinition
    use PedigreeDefinition
    use Constants

    character(len = 300) :: filout
    integer :: i, j, nSurrogates

    type(Surrogate), intent(in) :: definition
    integer, intent(in) :: threshold
    integer, intent(in) :: OutputPoint
    type(Pedigree), intent(in) :: p

    integer :: nAnisG
    character(len=100) :: fmt

    nAnisG = size(definition%numOppose,1)

    write (filout, '(".",a1,"Miscellaneous",a1,"Surrogates",i0,".txt")') SEP, SEP, OutputPoint
    open (unit = 13, FILE = filout, status = 'unknown')
    write (filout, '(".",a1,"Miscellaneous",a1,"SurrogatesSummary",i0,".txt")') SEP, SEP, OutputPoint
    open (unit = 19, FILE = filout, status = 'unknown')
    write(fmt, '(a,i10,a)') '(a20,', size(definition%partition,2), 'i6)'
    do i = 1, nAnisG
      nSurrogates = 0
      write (13, fmt) p%getID(i), definition%partition(i,:)
      do j = 1, nAnisG
	if (definition%numOppose(i, j) <= threshold) nSurrogates = nSurrogates + 1
      enddo
      write (19, '(a20,5i8)') &
      p%getID(i), count(definition%partition(i,:) == 1), count(definition%partition(i,:) == 2)&
      , count(definition%partition(i,:) == 3), nSurrogates, definition%method(i)
    enddo
    close(13)
    close(19)

  end subroutine WriteSurrogates

!#################################################################################################################################################################

  subroutine CountInData(nAnisRawPedigree, nAnisG, params)
    use ParametersDefinition
    
    type(Parameters), intent(in) :: params
    integer, intent(out) :: nAnisRawPedigree, nAnisG

    integer :: k
    character (len = 300) :: dumC

    nAnisRawPedigree = 0
    if (trim(params%PedigreeFile) /= "NoPedigree") then
      open (unit = 2, file = trim(params%PedigreeFile), status = "old")
      do
	read (2, *, iostat = k) dumC
	nAnisRawPedigree = nAnisRawPedigree + 1
	if (k /= 0) then
	  nAnisRawPedigree = nAnisRawPedigree - 1
	  exit
	endif
      enddo
      close(2)
      print*, " ", nAnisRawPedigree, " individuals in the pedigree file"
    endif

    nAnisG = 0
    open (unit = 3, file = trim(params%GenotypeFile), status = "old")
    do
      read (3, *, iostat = k) dumC
      nAnisG = nAnisG + 1
      if (k /= 0) then
	nAnisG = nAnisG - 1
	exit
      endif
    enddo
    if (params%GenotypeFileFormat == 2) then
      nAnisG = nAnisG /2
    end if
    close(3)
    print*, " ", nAnisG, " individuals in the genotype file"

    if (trim(params%PedigreeFile) == "NoPedigree") nAnisRawPedigree = nAnisG

  end subroutine CountInData

!########################################################################################################################################################################################################

  subroutine MakeDirectories(params)
    use ParametersDefinition
    use Constants
    
    type(Parameters), intent(in) :: params
    
    print*, ""
    call system(RMDIR // "Miscellaneous")
    call system(RMDIR // "PhasingResults")

    call system(MKDIR // "PhasingResults")
    call system(MKDIR // "PhasingResults"//SEP//"HaplotypeLibrary")
    if (params%FullFileOutput) call system(MKDIR // "PhasingResults"//SEP//"HaplotypeLibrary"//SEP//"Extras")
    call system(MKDIR // "Miscellaneous")
    
    if (params%Simulation) then
      call system(RMDIR // "Simulation")
      if (params%FullFileOutput) then
	call system(MKDIR // "Simulation")
      endif
    end if

  end subroutine MakeDirectories  
  
  subroutine WriteHapLib(library, currentcore, c, params)
    use ParametersDefinition
    use HaplotypeLibraryDefinition
    use Constants
    use CoreDefinition
    
    type(HaplotypeLibrary), intent(in) :: library
    type(Core), intent(in) :: c
    integer, intent(in) :: currentcore
    type(Parameters) :: params

    integer :: i, j, k, counter, SizeCore, nHaps !, nAnisG
    character(len = 300) :: filout

    SizeCore = library%getNumSnps()

    nHaps = library%getSize()

    if (params%FullFileOutput) then
      write (filout, '(".",a1,"PhasingResults",a1,"HaplotypeLibrary",a1,"HapLib",i0,".txt")') SEP, SEP, SEP, currentcore
      open (unit = 24, FILE = filout, status = 'unknown')
    endif
    write (filout, '(".",a1,"PhasingResults",a1,"HaplotypeLibrary",a1,"HapLib",i0,".bin")') SEP, SEP, SEP, currentcore
    open (unit = 34, FILE = filout, form = "unformatted", status = 'unknown')

    write (34) nHaps, SizeCore
    do i = 1, nHaps
      if (params%FullFileOutput)&
      write (24, '(2i6,a2,20000i1,20000i1,20000i1,20000i1,20000i1,20000i1,20000i1,20000i1,20000i1,20000i1,20000i1,20000i1)') &
      i, library%getHapFreq(i), " ", library%getHap(i)
      write (34) library%getHap(i)
    end do

    if (params%FullFileOutput) then
      close(24)
    end if
    close(34)

    if (params%ItterateType .eq. "Off") then
      print*, "   ", "Final iteration found ", nHaps, "haplotypes"
    
      print*, ""
      write (*, '(a4,a30,f5.2,a1)') "   ", "Final yield for this core was ", c%getTotalYield(), "%"
    end if
    
    open (unit = 29, file = "."//SEP//"PhasingResults"//SEP//"PhasingYield.txt", status = "unknown", position = "append")

    write (29, '(i10,f7.2)') CurrentCore, c%getTotalYield()

    close(29)

  end subroutine WriteHapLib
  
  subroutine writeTimer(hours, minutes, seconds)
    integer, intent(in) :: hours, minutes
    real, intent(in) :: seconds
    
    open (unit = 32, file = "."//SEP//"PhasingResults"//SEP//"Timer.txt", status = "unknown")

    write(32, '(A27,A7,I3,A9,I3,A9,F6.2)') "Time Elapsed", "Hours", INT(Hours), "Minutes", INT(Minutes), "Seconds", Seconds

    close(32)
  end subroutine writeTimer
  
  subroutine WriteTestResults(results, c, Surrogates, p, TruePhase, OutputPoint, OutputSurrogates)
    use Constants
    use SurrogateDefinition
    use PedigreeDefinition
    use CoreDefinition
    use TestResultDefinition

    type(TestResults), intent(in) :: results
    type(Core), intent(in) :: c
    type(Surrogate), intent(in) :: surrogates
    type(Pedigree), intent(in) :: p
    !! Probably should be consistent about what we call this
    integer(kind=1), dimension(:,:,:), intent(in) :: TruePhase
    logical, intent(in) :: OutputSurrogates
    integer, intent(in) :: OutputPoint

    integer :: i, j, k, nSurrogates
    integer(kind = 1), allocatable, dimension(:,:,:) :: MistakePhase
    character(len = 300) :: filout

    integer(kind = 1), allocatable, dimension(:) :: holdPhase

    integer :: nAnisG, nSnp

    nAnisG = c % getNAnisG()
    nSNp = c % getNCoreSnp()

    write (filout, '(".",a1,"Simulation",a1,"IndivMistakes",i0,".txt")') SEP, SEP, OutputPoint
    open (unit = 17, FILE = filout, status = 'unknown')
    write (filout, '(".",a1,"Simulation",a1,"IndivMistakesPercent",i0,".txt")') SEP, SEP, OutputPoint
    open (unit = 20, FILE = filout, status = 'unknown')
    write (filout, '(".",a1,"Simulation",a1,"CoreMistakesPercent.txt")') SEP, SEP
    open (unit = 31, FILE = filout, status = 'unknown', position = 'append')

    do i = 1, nAnisG
      if (outputSurrogates) then
	nSurrogates = 0
	do k = i, nAnisG
	  if (surrogates % numOppose(i, k) <= surrogates % threshold) nSurrogates = nSurrogates + 1
	enddo
	write (17, '(a20,a3,3i5,a3)', advance='no') p % getID(i), "|", &
	count(surrogates % partition(i,:) == 1), count(surrogates % partition(i,:) == 2), nSurrogates, "|"
	write (20, '(a20,a3,3i5,a3)',advance='no') p % getId(i), "|", &
	count(surrogates % partition(i,:) == 1), count(surrogates % partition(i,:) == 2), nSurrogates, "|"
      else
	write (17, '(a20,a3,3i5,a3)', advance='no') p % getID(i), "|", &
	-1, -1, -1, "|"
	write (20, '(a20,a3,3i5,a3)', advance='no') p % getID(i), "|", &
	-1, -1, -1, "|"
      end if
      write(17, '(6i6,a6,6i6,a6,6i6,a6,6i6)') &
      results%counts(i,1,ALL_,CORRECT_), results%counts(i,2,ALL_,CORRECT_), &
      results%counts(i,1,ALL_,NOTPHASED_), results%counts(i,2,ALL_,NOTPHASED_), &
      results%counts(i,1,ALL_,INCORRECT_), results%counts(i,2,ALL_,INCORRECT_), "|", &
      results%counts(i,1,HET_,CORRECT_), results%counts(i,2,HET_,CORRECT_), &
      results%counts(i,1,HET_,NOTPHASED_), results%counts(i,2,HET_,NOTPHASED_), &
      results%counts(i,1,HET_,INCORRECT_), results%counts(i,2,HET_,INCORRECT_), "|", &
      results%counts(i,1,MISS_,CORRECT_), results%counts(i,2,MISS_,CORRECT_), &
      results%counts(i,1,MISS_,NOTPHASED_), results%counts(i,2,MISS_,NOTPHASED_), &
      results%counts(i,1,MISS_,INCORRECT_), results%counts(i,2,MISS_,INCORRECT_), "|", &
      results%counts(i,1,ERROR_,CORRECT_), results%counts(i,2,ERROR_,CORRECT_), &
      results%counts(i,1,ERROR_,NOTPHASED_), results%counts(i,2,ERROR_,NOTPHASED_), &
      results%counts(i,1,ERROR_,INCORRECT_), results%counts(i,2,ERROR_,INCORRECT_)
      write (20, '(6f7.1,a6,6f7.1,a6,6f7.1,a6,6f7.1)') &
      results%percent(i,1,ALL_,CORRECT_), results%percent(i,2,ALL_,CORRECT_), &
      results%percent(i,1,ALL_,NOTPHASED_), results%percent(i,2,ALL_,NOTPHASED_), &
      results%percent(i,1,ALL_,INCORRECT_), results%percent(i,2,ALL_,INCORRECT_), "|", &
      results%percent(i,1,HET_,CORRECT_), results%percent(i,2,HET_,CORRECT_), &
      results%percent(i,1,HET_,NOTPHASED_), results%percent(i,2,HET_,NOTPHASED_), &
      results%percent(i,1,HET_,INCORRECT_), results%percent(i,2,HET_,INCORRECT_), "|", &
      results%percent(i,1,MISS_,CORRECT_), results%percent(i,2,MISS_,CORRECT_), &
      results%percent(i,1,MISS_,NOTPHASED_), results%percent(i,2,MISS_,NOTPHASED_), &
      results%percent(i,1,MISS_,INCORRECT_), results%percent(i,2,MISS_,INCORRECT_), "|", &
      results%percent(i,1,ERROR_,CORRECT_), results%percent(i,2,ERROR_,CORRECT_), &
      results%percent(i,1,ERROR_,NOTPHASED_), results%percent(i,2,ERROR_,NOTPHASED_), &
      results%percent(i,1,ERROR_,INCORRECT_), results%percent(i,2,ERROR_,INCORRECT_)
    end do
    
    write (31, '(6f9.4)') &
    (results%percentAll(1,ALL_,CORRECT_) + results%percentAll(2,ALL_,CORRECT_)) / 2, &
    (results%percentAll(1,HET_,CORRECT_) + results%percentAll(2,HET_,CORRECT_)) / 2, &
    (results%percentAll(1,ALL_,NOTPHASED_) + results%percentAll(2,ALL_,NOTPHASED_)) / 2, &
    (results%percentAll(1,HET_,NOTPHASED_) + results%percentAll(2,HET_,NOTPHASED_)) / 2, &
    (results%percentAll(1,ALL_,INCORRECT_) + results%percentAll(2,ALL_,INCORRECT_)) / 2, &
    (results%percentAll(1,HET_,INCORRECT_) + results%percentAll(2,HET_,INCORRECT_)) / 2

    close(17)
    close(20)
    close(31)
  end subroutine WriteTestResults

  subroutine CombineTestResults(nCores)
    use Constants

    integer, intent(in) :: nCores

    character(len = 300) :: filout
    double precision, allocatable, dimension(:,:) :: AverageMatrix
    
    integer :: i

    allocate(AverageMatrix(nCores, 6))
    write (filout, '(".",a1,"Simulation",a1,"CoreMistakesPercent.txt")') SEP, SEP
    open (unit = 31, FILE = filout, status = 'unknown')
    do i = 1, nCores
      read (31, *) AverageMatrix(i,:)
    end do
    write (31, *) " "
    write (31, '(6f9.4)') sum(AverageMatrix(:, 1))/nCores, sum(AverageMatrix(:, 2))/nCores, sum(AverageMatrix(:, 3))/nCores, &
    sum(AverageMatrix(:, 4))/nCores, sum(AverageMatrix(:, 5))/nCores, sum(AverageMatrix(:, 6))/nCores
    deallocate(AverageMatrix)
  end subroutine CombineTestResults
  
  subroutine WriteMistakes(c, TruePhase, p, OutputPoint)
    use Constants
    use CoreDefinition
    use PedigreeDefinition
    
    type(Core), intent(in) :: c
    !! Probably should be consistent about what we call this
    integer(kind=1), dimension(:,:,:), intent(in) :: TruePhase
    type(Pedigree), intent(in) :: p
    integer, intent(in) :: OutputPoint
    
    integer :: i, j, k
    integer(kind = 1), allocatable, dimension(:) :: MistakePhase
    character(len = 300) :: dumC, filout
    
    allocate(MistakePhase(c%getNCoreSnp()))

    write (filout, '(".",a1,"Simulation",a1,"Mistakes",i0,".txt")') SEP, SEP, OutputPoint
    open (unit = 18, FILE = filout, status = 'unknown') 
    
    do i = 1, c%getNAnisG()
      do k = 1, 2
	do j = 1, c%getNCoreSnp()
	  if (c % getPhase(i, j, k) == MissingPhaseCode) then
	    MistakePhase(j) = MissingPhaseCode
	  else
	    if (TruePhase(i, j, k) == c % getPhase(i, j, k)) then
	      MistakePhase(j) = 1
	    else
	      MistakePhase(j) = 5
	    end if
	  endif
	end do
      
	write (18, '(a20,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3)') p % getID(i),&
	MistakePhase
      end do
    end do
    
    close(18)
    
  end subroutine WriteMistakes
  
  function BinarySearch(array, val) result(pos)
    character(*), dimension(:), intent(in) :: array
    character(*), intent(in) :: val
    integer :: pos
    
    integer :: low, high, mid
    
    low = 1
    high = size(array)
    
    do while (low <= high)
      mid = (low + high) / 2
      if (array(mid) > val) then
	high = mid - 1
      end if
      if (array(mid) < val) then
	low = mid + 1
      end if
      if (array(mid) == val) then
	pos = mid
	return 
      end if
    end do
    
    pos = 0
  end function
  

  function getCoresFromHapLib(directory) result (CoreIndex)
    character(*), intent(in) :: directory
    integer, dimension(:,:), pointer :: CoreIndex

    integer :: i, numLibraries, start, nHaps, nSnps, ltail, rtail
    character(4096) :: filename
    logical :: ex

    i = 1
    write (filename, '(a, a, "HapLib", i0, ".bin")') trim(directory), SEP, i 
    inquire(FILE=filename, EXIST=ex)
    do while (ex)
      i = i + 1
      write (filename, '(a, a, "HapLib", i0, ".bin")') trim(directory), SEP, i
      inquire(FILE=filename, EXIST=ex)
    end do
    numLibraries = i - 1
    
    allocate(CoreIndex(numLibraries,2))
    start = 1
    
    do i = 1, numLibraries
      write (filename, '(a, a, "HapLib", i0, ".bin")') trim(directory), SEP, i
      open (unit=2001,file=trim(filename),status="old",form="unformatted")
      read(2001) nHaps,nSnps
      close(2001)
      
      CoreIndex(i,1) = start
      CoreIndex(i,2) = start + nSnps - 1
      
      start = start + nSnps
    end do
  end function getCoresFromHapLib
  
  function getHaplotypeLibrary(directory, index) result (library)
    use HaplotypeLibraryDefinition
    
    character(*), intent(in) :: directory
    integer, intent(in) :: index
    type(HaplotypeLibrary) :: library
    
    character(4096) :: filename
    
    write (filename, '(a, a, "HapLib", i0, ".bin")') trim(directory), SEP, index
    library = HaplotypeLibrary(filename,500)
  end function getHaplotypeLibrary
  
end module InputOutput
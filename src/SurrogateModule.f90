module SurrogateModule
  use GenotypeMOdule
  implicit none


!< surrogates are animal pairs that should share haplotypes
  type :: Surrogate
    integer(kind = 2), allocatable, dimension(:,:) :: numOppose !< opposing homozygotes between two aniam;s 
    logical, allocatable, dimension(:,:) :: enoughInCommon
    integer(kind = 1), allocatable, dimension(:,:) :: partition !< partion every animal into paternal or maternal surrogate
    integer(kind = 1), allocatable, dimension(:) :: method !< whether its sire or dam surrogate, 1 sire, 2 dam 
    integer :: threshold !< less than this number of homozygotes, then they are surragates
    integer :: incommonThreshold !< whether two animals have enough snps in common that you can define surragates
  contains
    final :: destroySurrogate
  end type Surrogate
  
  interface Surrogate
    module procedure newSurrogate
  end interface Surrogate

contains
  function newSurrogate(cs, threshold, incommonThreshold) result(definition)
    use ClusteringModule
    use CoreSubSetModule
    
    class(CoreSubSet), intent(in) :: cs    
    integer, intent(in) :: threshold
    integer, intent(in) :: incommonThreshold
    type(Surrogate) :: definition
    
    type(Genotype), dimension (:), pointer :: genos
    
    integer, allocatable, dimension(:,:) :: passThres
    integer, allocatable, dimension(:) :: numPassThres

    integer :: nAnisG, nSnp
    
    integer :: i, j, k, Counter, nSnpCommon
    integer, allocatable, dimension(:) :: ProgCount
    integer :: CountAgreePat, CountAgreeMat, DumSire, DumDam

    integer :: aj, ak
    integer :: pass
    
    
    integer, allocatable, dimension (:,:) :: TempSurrArray
    integer, allocatable, dimension (:) :: TempSurrVector
    integer :: rounds, SurrCounter
    integer, allocatable, dimension (:) :: ClusterMember

    definition%threshold = threshold
    nAnisG = cs%getNAnisGCoreSubset()
    nSnp = cs%getNCoreTailSnpCoreSubset()
    genos => cs%getCoreAndTailGenosCoreSubset()

    allocate(ProgCount(nAnisG)) !< how many prog each animal has 

    allocate(passThres(nAnisG, nAnisG)) !< list of surragates for a given animal
    allocate(numPassThres(nAnisG)) !< count of how many surragates animal has
    numPassThres = 0
    passThres = 0

    if (allocated(definition%partition)) then
      deallocate(definition%partition)
      deallocate(definition%numoppose)
      deallocate(definition%enoughIncommon)      
      deallocate(definition%method)
    end if
    allocate(definition%partition(nAnisG,nAnisG))
    allocate(definition%numoppose(nAnisG,nAnisG))
    allocate(definition%enoughIncommon(nAnisG,nAnisG))
    allocate(definition%method(nAnisG))

    definition%partition = 0
    definition%numoppose = 0
    definition%enoughInCommon = .true.
    definition%method = 0
    
    if (inCommonThreshold > 0) then
      do i = 1, nAnisG
	do j = i + 1, nAnisG
	  nSnpCommon = genos(i)%numIncommon(genos(j))
	  
	  definition%enoughIncommon(i,j) = (nSnpCommon >= incommonThreshold)
	  definition%enoughIncommon(j,i) = (nSnpCommon >= incommonThreshold)	
	end do
      end do
    end if
	  
	  
    do i = 1, nAnisG
      pass = 0
      do j = i + 1, nAnisG
	Counter = 0
	nSnpCommon = 0

	Counter = genos(i)%mismatches(genos(j))
	

	definition%numoppose(i, j) = Counter
	definition%numoppose(j, i) = Counter

	if ((Counter <= threshold) .and. (definition%enoughIncommon(i,j))) then
	  numPassThres(i) = numPassThres(i) + 1
	  passThres(i, numPassThres(i)) = j
	  numPassThres(j) = numPassThres(j) + 1
	  passThres(j, numPassThres(j)) = i 
	end if
      end do
      definition%numoppose(i, i) = 0
    end do
    
    ProgCount = 0
    do i = 1, nAnisG
      if (cs%getSireCoreSubset(i) /= 0) then
	ProgCount(cs%getSireCoreSubset(i)) = ProgCount(cs%getSireCoreSubset(i)) + 1
      end if
      if (cs%getDamCoreSubset(i) /= 0) then
	ProgCount(cs%getDamCoreSubset(i)) = ProgCount(cs%getDamCoreSubset(i)) + 1
      end if
    end do

    do i = 1, nAnisG

      DumSire = 0
      DumDam = 0

      if ((cs%getSireCoreSubset(i) /= 0).and.(cs%getDamCoreSubset(i) /= 0)) then
	do aj = 1, numPassThres(i)
	  j = passThres(i, aj)
	  if ((definition%numoppose((cs%getSireCoreSubset(i)), j) <=  threshold) &
	    .and.(definition%numoppose((cs%getDamCoreSubset(i)), j) > threshold)) then
	    if (definition%enoughIncommon(cs%getSireCoreSubset(i), j) &
	      .and. definition%enoughIncommon(cs%getDamCoreSubset(i), j)) then
	      definition%partition(i, j) = 1
	    end if
	  endif
	  if ((definition%numoppose((cs%getDamCoreSubset(i)), j) <= threshold)&
	    .and.(definition%numoppose((cs%getSireCoreSubset(i)), j) > threshold)) then
	    if (definition%enoughIncommon(cs%getSireCoreSubset(i), j) &
	      .and. definition%enoughIncommon(cs%getDamCoreSubset(i), j)) then
	      definition%partition(i, j) = 2
	    end if
	  endif
	end do
	if (definition%numoppose(i, cs%getSireCoreSubset(i)) <= threshold) then
	  if (definition%enoughIncommon(cs%getSireCoreSubset(i), j)) then
	    definition%partition(i, cs%getSireCoreSubset(i)) = 1
	  end if
	end if
	if (definition%numoppose(i, cs%getDamCoreSubset(i)) <= threshold) then
	  if (definition%enoughIncommon(cs%getDamCoreSubset(i), j)) then
	    definition%partition(i, cs%getDamCoreSubset(i)) = 2
	  end if
	end if
	definition%method(i) = 1
      end if

      if ((definition%method(i) == 0).and.(cs%getSireCoreSubset(i) /= 0)) then
	definition%partition(i, cs%getSireCoreSubset(i)) = 1
	do aj = 1, numPassThres(i)
	  j = passThres(i, aj)
	  if (definition%numoppose(cs%getSireCoreSubset(i), j) <= threshold) then
	    if (definition%enoughIncommon(cs%getSireCoreSubset(i), j)) then
	      definition%partition(i, j) = 1
	    end if
	  endif
!	  if (definition%numoppose(cs%getSireCoreSubset(i), j) > threshold) then
!	    if (definition%enoughIncommon(cs%getSireCoreSubset(i), j)) then
!	      definition%partition(i, j) = 2
!	    end if
!	  end if
	enddo
	definition%method(i) = 2
      endif

      if ((definition%method(i) == 0).and.(cs%getDamCoreSubset(i) /= 0)) then
	definition%partition(i, cs%getDamCoreSubset(i)) = 2
	do aj = 1, numPassThres(i)
	  j = passThres(i, aj)
	  if (definition%numoppose(cs%getDamCoreSubset(i), j) <= threshold) then
	    if (definition%enoughIncommon(cs%getDamCoreSubset(i), j)) then
	      definition%partition(i, j) = 2
	    end if
	  endif
!	  if (definition%numoppose(cs%getDamCoreSubset(i), j) > threshold) then
!	    if (definition%enoughIncommon(cs%getDamCoreSubset(i), j)) then
!	      definition%partition(i, j) = 1
!	    end if
!	  end if
	enddo
	definition%method(i) = 3
      endif
      
      if ((definition%method(i) == 0).and.(ProgCount(i) /= 0)) then
	DumSire = 0
	do aj = 1, numPassThres(i)
	  j = passThres(i, aj)
	  if (i == cs%getDamCoreSubset(j)) then
	    DumSire = j
	    exit
	  endif
	  if (i == cs%getSireCoreSubset(j)) then
	    DumSire = j
	    exit
	  endif
	end do
	if (DumSire /= 0) then
	  definition%partition(i, DumSire) = 1
	  do aj = 1, numPassThres(i)
	    j = passThres(i, aj)
	    if ((i == cs%getSireCoreSubset(j)).or.(i == cs%getDamCoreSubset(j))) then
	      if (definition%numoppose(j, DumSire) > threshold) then
		if (definition%enoughIncommon(j, DumSire)) then
		  definition%partition(i, j) = 2
		  exit
		end if
	      else
		if (definition%enoughIncommon(j, DumSire)) then
		  definition%partition(i, j) = 1
		  exit
		end if
	      endif
	    end if
	  end do
	end if
	definition%method(i) = 5
      end if

      if (definition%method(i) > 1) then
	do aj = 1, numPassThres(i)
          j = passThres(i, aj)
	  CountAgreePat = 0
	  CountAgreeMat = 0
	  do ak = 1, numPassThres(j)
	    k = passThres(j, ak)
	      if (definition%partition(i, k) == 1) then
		CountAgreePat = CountAgreePat + 1
		exit !here
	      endif
	      if (definition%partition(i, k) == 2) then
		CountAgreeMat = CountAgreeMat + 1
		exit !here
	      endif
	  end do
	  if ((CountAgreePat /= 0).and.(CountAgreeMat == 0)) then
	    definition%partition(i, j) = 1
	  end if
	  if ((CountAgreePat == 0).and.(CountAgreeMat /= 0)) then
	    definition%partition(i, j) = 2
	  end if
	end do
      end if
      
      if (definition%method(i) == 0) then
	SurrCounter = numPassThres(i)
	if (SurrCounter > 0) then
	  allocate(TempSurrArray(SurrCounter, SurrCounter))
	  allocate(TempSurrVector(SurrCounter))
	  SurrCounter = 0
	  do j = 1, nAnisG
	    if ((definition%numoppose(i, j) <= threshold).and.(i /= j)) then
	      if (definition%enoughIncommon(i, j)) then
		SurrCounter = SurrCounter + 1
		TempSurrVector(SurrCounter) = j
	      end if
	    endif
	  end do
	  TempSurrArray = 0
	  do j = 1, SurrCounter
	    do k = 1, SurrCounter
	      if (definition%numoppose(TempSurrVector(j), TempSurrVector(k)) <= threshold) then
		if (definition%enoughIncommon(TempSurrVector(j), TempSurrVector(k))) then
		  TempSurrArray(j, k) = 1
		end if
	      end if
	    end do
	    TempSurrArray(j, j) = 1
	  end do

	  allocate(ClusterMember(SurrCounter))
	  ClusterMember(1) = 1
	  do j = 1, SurrCounter
	    if (TempSurrArray(1, j) == 0) then
	      ClusterMember(j) = 2
	    else
	      ClusterMember(j) = 1
	    endif
	  end do
	  rounds = cluster(TempSurrArray, ClusterMember, 2, SurrCounter, .true.)
	  if (rounds <= SurrCounter) then
	    do j = 1, SurrCounter
	      definition%partition(i, TempSurrVector(j)) = ClusterMember(j)
	    enddo
	    definition%method(i) = 7
	  end if

	  deallocate(ClusterMember)
	  deallocate(TempSurrArray)
	  deallocate(TempSurrVector)
	endif
	definition%method(i) = 6
      endif
      definition%partition(i, i) = 0
          
      if (definition%method(i) > 3) then
	call cs%setSwappableCoreSubset(i, definition%method(i))
      end if
    end do
    
    deallocate(genos)
  end function newSurrogate
  
  subroutine destroySurrogate(definition)
    type(Surrogate) :: definition
    
    if (allocated(definition%partition)) then
      deallocate(definition%partition)
      deallocate(definition%numoppose)
      deallocate(definition%method)
    end if
    
  end subroutine destroySurrogate
    
end module SurrogateModule
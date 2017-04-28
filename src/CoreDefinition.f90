module CoreDefinition
  use ConstantModule
  use GenotypeModule
  use HaplotypeModule
  implicit none

  type :: Core
    type(Genotype), dimension(:), pointer :: coreAndTailGenos
    type(Genotype), dimension(:), pointer :: coreGenos
    type(Haplotype), dimension(:,:), pointer :: phase
    integer, dimension(:,:), allocatable :: hapAnis

    integer(kind=1), dimension(:), allocatable :: swappable

    integer :: nCoreAndTailSnps, nCoreSnps

  contains
    procedure :: getCoreAndTailGenos
    procedure :: getNAnisG
    procedure :: getNSnp
    procedure :: getNCoreSnp
    procedure :: getNCoreTailSnp
    procedure :: getYield
    procedure :: getTotalYield
    procedure :: getPercentFullyPhased
    procedure :: getCoreGenos
    procedure :: flipHaplotypes
    procedure :: bestDiscriminators
    
    final :: destroyCore
  end type Core
  
  interface Core
    module procedure newCore
    module procedure newPhaseCore
  end interface Core

contains

  function newCore(p, startTailSnp, startCoreSnp, endCoreSnp, endTailSnp) result(c)
    use PedigreeModule

    type(PedigreeHolder), intent(in) :: p
    integer, intent(in) :: startCoreSnp, endCoreSnp, startTailSnp, endTailSnp
    type(Core) :: c
    type(Genotype) :: tempFullGeno

    integer :: nAnisG, i


    nAnisG = p%nHd
    c%nCoreAndTailSnps = endTailSnp - startTailSnp + 1
    c%nCoreSnps = endCoreSnp - startCoreSnp + 1

    allocate(c%coreAndTailGenos(nAnisG))
    allocate(c%coreGenos(nAnisG))
    allocate(c%phase(nAnisG,2))

    do i = 1, nAnisG
      tempFullGeno = p%pedigree(p%hdMap(i))%individualGenotype
      c%coreGenos(i) = tempFullGeno%subset(startCoreSnp, endCoreSnp)
      c%coreAndTailGenos(i) = tempFullGeno%subset(startTailSnp, endTailSnp)
      c%phase(i,1) = Haplotype(c%nCoreSnps)
      c%phase(i,2) = Haplotype(c%nCoreSnps)
    end do
    
    allocate(c%hapAnis(nAnisG,2))
    
    allocate(c%swappable(nAnisG)) 

    c%hapAnis = MissingHaplotypeCode

    c%swappable = 0
  end function newCore

  function newPhaseCore(phase, startSnp, endSnp) result(c)

    type(Haplotype), dimension(:,:), intent(in) :: phase
    integer, intent(in) :: startSnp, endSnp
    type(Core) :: c

    integer :: nAnisG, i
    type(Haplotype) :: tempFullHaplotype

    nAnisG = size(phase,1)

    allocate(c%phase(nAnisG,2))
    allocate(c%hapAnis(nAnisG,2))

    c%nCoreSnps = endSnp - startSnp + 1
    c%nCoreAndTailSnps = c%nCoreSnps
    do i = 1, size(phase,1)
      tempFullHaplotype = Phase(i,1)
      c%phase(i,1) = tempFullHaplotype%subset(startSnp,endSnp)
      tempFullHaplotype = Phase(i,2)
      c%phase(i,2) = tempFullHaplotype%subset(startSnp,endSnp)
    end do
    c%hapAnis = MissingHaplotypeCode
  end function newPhaseCore

  subroutine destroyCore(c)
    type(Core) :: c
    
    if (associated(c%coreGenos)) then
      deallocate(c%hapAnis)
    end if
  end subroutine destroyCore

  function getCoreAndTailGenos(c) result (ctGenos)
    ! use GenotypeModule needed here due to compiler issues (Roberto / 16.0.3)
    use GenotypeModule
    class(Core), target :: c
    type(Genotype), dimension(:), pointer :: ctGenos

    ctGenos => c%coreAndTailGenos

    return
  end function getCoreAndTailGenos

  function getNAnisG(c) result(num)
    class(Core) :: c
    integer :: num

    num = size(c%phase,1)
  end function getNAnisG

  function getNSnp(c) result(num)
    class(Core) :: c
    integer :: num

    num = c%nCoreAndTailSnps
  end function getNSnp

  function getNCoreSnp(c) result(num)
    class(Core) :: c
    integer :: num

    num = c%nCoreSnps
  end function getNCoreSnp

  function getNCoreTailSnp(c) result(num)
    class(Core) :: c
    integer :: num

    num = c%nCoreAndTailSnps
  end function getNCoreTailSnp

  function getYield(c,phase) result (yield)
    class(Core) :: c
    integer, intent(in) :: phase
    integer :: counter, i
    double precision :: yield
    
    counter = 0
    
    do i = 1, size(c%phase,1)
      counter = counter + c%phase(i,phase)%numberNotMissing()
    end do
    
    yield = (float(counter)/(size(c%phase,1) * c%getNCoreSnp())) * 100
  end function getYield

  function getTotalYield(c) result(yield)
    class(Core) :: c
    integer :: counter, i
    double precision :: yield

    counter = 0
    do i = 1, size(c%phase,1)
      counter = counter + c%phase(i,1)%numberNotMissing()
      counter = counter + c%phase(i,2)%numberNotMissing()
    end do
    yield = (float(counter)/(size(c%phase,1) * c%nCoreSnps * 2)) * 100
  end function getTotalYield

  function getHaplotype(c,animal, phase) result(haplotype)
    class(Core) :: c
    integer, intent(in) :: animal, phase
    type(Haplotype), pointer :: haplotype

    haplotype => c%phase(animal,phase)
  end function getHaplotype
  
  function getPercentFullyPhased(c) result (percent)
    class(Core) :: c
    double precision :: percent
    
    integer :: count, i, j
    
    count = 0
    do i = 1, size(c%phase,1)
      do j = 1, 2
	if (c%phase(i,j)%fullyPhased()) then
	  count = count + 1
	end if
      end do
    end do
    
    percent = 100.0 * float(count) / (size(c%phase,1)*2)
    
  end function getPercentFullyPhased
  
  function getCoreGenos(c,animal) result(g)
    use GenotypeModule
    class(Core), intent(in) :: c
    integer, intent(in) :: animal

    type(Genotype), pointer :: g

    g => c%coreGenos(animal)
  end function getCoreGenos

  subroutine flipHaplotypes(c, TruePhase)
    use HaplotypeModule

    class(Core) :: c
    type(Haplotype), dimension(:,:), pointer, intent(in) :: TruePhase

    integer :: i, j, CountAgreeStay1, CountAgreeStay2, CountAgreeSwitch1, CountAgreeSwitch2, truth
    type(Haplotype) :: W1, W2
    type(Haplotype), pointer :: hap1, hap2, truehap1, truehap2
    integer :: HA1, HA2
    integer :: nAnisG, nSnp

    nAnisG = c%getNAnisG()
    nSnp = c%getNCoreSnp()

    do i = 1, nAnisG
      CountAgreeStay1 = 0
      CountAgreeStay2 = 0
      CountAgreeSwitch1 = 0
      CountAgreeSwitch2 = 0
      truth = 0
      hap1 => c%phase(i,1)
      hap2 => c%phase(i,2)
      truehap1 => TruePhase(i,1)
      truehap2 => TruePhase(i,2)
      !! This could be done with bit ops but is not a priority given it's only used when comparing to known phase
      do j = 1, nSnp
	if (truehap1.getPhaseMod(j) == hap1%getPhaseMod(j)) CountAgreeStay1 = CountAgreeStay1 + 1
	if (truehap2.getPhaseMod(j) == hap1%getPhaseMod(j)) CountAgreeSwitch1 = CountAgreeSwitch1 + 1
	if (truehap1.getPhaseMod(j) == hap2%getPhaseMod(j)) CountAgreeSwitch2 = CountAgreeSwitch2 + 1
	if (truehap2.getPhaseMod(j) == hap2%getPhaseMod(j)) CountAgreeStay2 = CountAgreeStay2 + 1
      end do
      if ((CountAgreeSwitch2 > CountAgreeStay2).and.(CountAgreeStay1 <= CountAgreeSwitch1)) truth = 1
      if ((CountAgreeSwitch1 > CountAgreeStay1).and.(CountAgreeStay2 <= CountAgreeSwitch2)) truth = 1
      if (truth == 1) then
	W1 = c%phase(i,1)
	W2 = c%phase(i,2)
	c%phase(i,1) = W2
	c%phase(i,2) = W1
	
	HA1 = c%hapAnis(i,1)
	HA2 = c%hapAnis(i,2)
	c%hapAnis(i,1) = HA2
	c%hapAnis(i,2) = HA1
      end if
    end do

  end subroutine flipHaplotypes
  
  function bestDiscriminators(c, n) result(best)
    class(Core), intent(in) :: c
    integer, intent(in) :: n
    integer, dimension(:), pointer :: best
    
    integer, dimension(:), pointer :: workbest
    integer, dimension(c%getNAnisG(),2,2**n) :: assign
    integer, dimension(c%getNAnisG(),2) :: assigned
    integer(kind=8), dimension(0:2**n-1) :: counts
    integer :: i, j, k, l, nAnisG, nSnp, bestSnp, p, b
    integer(kind=8) :: bestDiff, lastDiff, diff
    logical :: used
    
    allocate(workbest(n))
    
    nAnisG = c%getNAnisG()
    nSnp = c%getNCoreSnp()
    
    assign = 0
    assigned = 1
    
    lastDiff = (nAnisG*2)**2
    
    do b = 1, n
      bestDiff = huge(bestDiff)
      do i = 1, nSnp
	used = .false.
	do j = 1, b - 1
	  if (i == workbest(j)) then
	    used = .true.
	  end if
	end do
	
	if (.not. used) then
	  counts = 0

	  do j = 1, nAnisG
	    do k = 1, 2
	      p = c%phase(j,k)%getPhaseMod(i)
	      select case (p)
		case (0)
		  do l = 1, assigned(j,k)
		    counts(assign(j,k,l) * 2) = counts(assign(j,k,l) * 2) + 1
		  end do
		case (1)
		  do l = 1, assigned(j,k)
		    counts(assign(j,k,l) * 2 + 1) = counts(assign(j,k,l) * 2 + 1) + 1
		  end do
		case default
		  do l = 1, assigned(i,k)
		    counts(assign(j,k,l) * 2) = counts(assign(j,k,l) * 2) + 1
		    counts(assign(j,k,l) * 2 + 1) = counts(assign(j,k,l) * 2 + 1) + 1
		  end do
	      end select
	    end do
	  end do

	  diff  = 0.0
	  do j = 0, (2**n) - 1
	    if (diff + counts(j)**2 < 0) then
	      print *, diff, diff + counts(j)**2, counts(j) ** 2, counts(j), j
	      call exit(0)
	    end if
	    diff = diff + counts(j)**2
	  end do

	  if (diff < bestDiff) then
	    bestSnp = i
	    bestDiff = diff
	  end if
	end if
      end do

      if (bestDiff < lastDiff) then
	workbest(b) = bestSnp
	do j = 1, nAnisG
	  do k = 1, 2
	    p = c%phase(j,k)%getPhaseMod(bestSnp)
	    select case (p)
	      case (0)
		do l = 1, assigned(j,k)
		  assign(j,k,l) = assign(j,k,l) * 2
		end do
	      case (1)
		do l = 1, assigned(j,k)
		  assign(j,k,l) = assign(j,k,l) * 2 + 1
		end do
	      case default
		do l = 1, assigned(j,k)
		  assign(j,k,l) = assign(j,k,l) * 2
		  assign(j,k,l+assigned(j,k)) = assign(j,k,l) + 1 !Already times it by 2
		end do
		assigned(j,k) = assigned(j,k) * 2
	    end select
	  end do
	end do      
	
	lastDiff = bestDiff
      else
	exit
      end if
      
      if (bestDiff == lastDiff) then
	best => workbest
      else
	allocate(best(b-1))
	best = workbest(1:b-1)
      end if
            
    end do
    
    print *
    print *, best
    

    
    call exit(0)
    
  end function bestDiscriminators

end module CoreDefinition


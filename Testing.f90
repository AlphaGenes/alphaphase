module Testing
  
contains

  subroutine Flipper(phase, startSnp,endSnp,totalSnps)
    use Parameters, only: TruePhaseFile
    implicit none

    integer(kind=1), dimension(:,:,:), intent(inout) :: phase
    integer,intent(in) :: startSnp, endSnp, totalSnps

    integer :: i, j, CountAgreeStay1, CountAgreeStay2, CountAgreeSwitch1, CountAgreeSwitch2, truth
    integer(kind = 1), allocatable, dimension(:,:,:) :: TruePhase
    integer(kind = 1), allocatable, dimension(:) :: W1, W2
    character(len = 300) :: dumC
    integer(kind=1), allocatable, dimension(:) :: holdPhase

    integer :: nAnisG, nSnp

    nAnisG = size(phase,1)
    nSnp = size(phase,2)

    allocate(TruePhase(nAnisG, nSnp, 2))
    allocate(W1(nSnp))
    allocate(W2(nSnp))
    allocate(holdPhase(totalSnps))
   

    open (unit = 16, file = trim(TruePhaseFile), status = "old")
    do i = 1, nAnisG
	read (16,*) dumC, holdPhase
	TruePhase(i,:,1) = holdPhase(startSnp:endSnp)
	read (16,*) dumC, holdPhase
	TruePhase(i,:,2) = holdPhase(startSnp:endSnp)
    end do
    close(16)

    do i = 1, nAnisG
      CountAgreeStay1 = 0
      CountAgreeStay2 = 0
      CountAgreeSwitch1 = 0
      CountAgreeSwitch2 = 0
      truth = 0
      do j = 1, nSnp
	if (TruePhase(i, j, 1) == Phase(i, j, 1)) CountAgreeStay1 = CountAgreeStay1 + 1
	if (TruePhase(i, j, 2) == Phase(i, j, 1)) CountAgreeSwitch1 = CountAgreeSwitch1 + 1
	if (TruePhase(i, j, 1) == Phase(i, j, 2)) CountAgreeSwitch2 = CountAgreeSwitch2 + 1
	if (TruePhase(i, j, 2) == Phase(i, j, 2)) CountAgreeStay2 = CountAgreeStay2 + 1
      end do
      if ((CountAgreeSwitch2 > CountAgreeStay2).and.(CountAgreeStay1 <= CountAgreeSwitch1)) truth = 1
      if ((CountAgreeSwitch1 > CountAgreeStay1).and.(CountAgreeStay2 <= CountAgreeSwitch2)) truth = 1
      if (truth == 1) then
	W1(:) = Phase(i, :, 1)
	W2(:) = Phase(i, :, 2)
	Phase(i, :, 1) = W2(:)
	Phase(i, :, 2) = W1(:)
      end if
    end do

  end subroutine Flipper
  
  !########################################################################################################################################################################

  subroutine Checker(c,Surrogates,p,OutputPoint,startSnp,endSnp,totalSnps)
    !!! THIS COULD DO WITH SOME MAJOR WORK!
    use Parameters, only: FullFileOutput, TruePhaseFile
    use Constants
    use SurrogateDefinition
    use PedigreeDefinition
    use CoreDefinition
    implicit none
    
    type(Core), intent(in) :: c
    type(SurrDef), intent(in) :: surrogates
    type(Pedigree), intent(in) :: p
    !! Probably should be consistent about what we call this
    integer,intent(in) :: OutputPoint
    integer,intent(in) :: startSnp, endSnp, totalSnps

    integer :: i,j,k,nSurrogates
    integer(kind=1),allocatable,dimension(:,:,:) :: TruePhase,MistakePhase
    integer,allocatable,dimension(:) :: HetCountPatWrong,HetCountPatNotPhased,HetCountPatCorrect,ErrCountMatWrong,ErrCountMatNotPhased
    integer,allocatable,dimension(:) :: ErrCountMatCorrect,MissCountMatWrong,MissCountMatNotPhased,MissCountMatCorrect,HetCountMatWrong
    integer,allocatable,dimension(:) :: HetCountMatNotPhased,HetCountMatCorrect,CountMatWrong,CountMatNotPhased
    integer,allocatable,dimension(:) :: CountMatCorrect,MissCountPatWrong
    integer,allocatable,dimension(:) :: MissCountPatNotPhased,MissCountPatCorrect,CountPatWrong,CountPatNotPhased,CountPatCorrect
    integer,allocatable,dimension(:) :: ErrCountPatWrong,ErrCountPatNotPhased,ErrCountPatCorrect
    double precision,allocatable,dimension(:) :: PercCountPatWrong,PercCountPatNotPhased,PercCountPatCorrect
    double precision,allocatable,dimension(:) :: PercHetCountPatWrong,PercHetCountPatNotPhased,PercHetCountPatCorrect
    double precision,allocatable,dimension(:) :: PercMissCountPatWrong,PercMissCountPatNotPhased,PercMissCountPatCorrect
    double precision,allocatable,dimension(:) :: PercErrCountPatWrong,PercErrCountPatNotPhased,PercErrCountPatCorrect
    double precision,allocatable,dimension(:) :: PercCountMatWrong,PercCountMatNotPhased,PercCountMatCorrect
    double precision,allocatable,dimension(:) :: PercHetCountMatWrong,PercHetCountMatNotPhased,PercHetCountMatCorrect
    double precision,allocatable,dimension(:) :: PercMissCountMatWrong,PercMissCountMatNotPhased,PercMissCountMatCorrect
    double precision,allocatable,dimension(:) :: PercErrCountMatWrong,PercErrCountMatNotPhased,PercErrCountMatCorrect
    character(len=300) :: dumC,filout
    
    integer(kind=1), allocatable, dimension(:) :: holdPhase
    
    integer :: nAnisG, nSnp
        
    nAnisG = c%getNAnisG()
    nSNp = c%getNCoreSnp()

    allocate(PercCountPatWrong(nAnisG))
    allocate(PercCountPatNotPhased(nAnisG))
    allocate(PercCountPatCorrect(nAnisG))
    allocate(PercHetCountPatWrong(nAnisG))
    allocate(PercHetCountPatNotPhased(nAnisG))
    allocate(PercHetCountPatCorrect(nAnisG))
    allocate(PercMissCountPatWrong(nAnisG))
    allocate(PercMissCountPatNotPhased(nAnisG))
    allocate(PercMissCountPatCorrect(nAnisG))
    allocate(PercErrCountPatWrong(nAnisG))
    allocate(PercErrCountPatNotPhased(nAnisG))
    allocate(PercErrCountPatCorrect(nAnisG))
    allocate(PercCountMatWrong(nAnisG))
    allocate(PercCountMatNotPhased(nAnisG))
    allocate(PercCountMatCorrect(nAnisG))
    allocate(PercHetCountMatWrong(nAnisG))
    allocate(PercHetCountMatNotPhased(nAnisG))
    allocate(PercHetCountMatCorrect(nAnisG))
    allocate(PercMissCountMatWrong(nAnisG))
    allocate(PercMissCountMatNotPhased(nAnisG))
    allocate(PercMissCountMatCorrect(nAnisG))
    allocate(PercErrCountMatWrong(nAnisG))
    allocate(PercErrCountMatNotPhased(nAnisG))
    allocate(PercErrCountMatCorrect(nAnisG))
    allocate(TruePhase(nAnisG,nSnp,2))
    allocate(MistakePhase(nAnisG,nSnp,2))
    allocate(HetCountPatWrong(nAnisG))
    allocate(HetCountPatNotPhased(nAnisG))
    allocate(HetCountPatCorrect(nAnisG))
    allocate(ErrCountMatWrong(nAnisG))
    allocate(ErrCountMatNotPhased(nAnisG))
    allocate(ErrCountMatCorrect(nAnisG))
    allocate(MissCountMatWrong(nAnisG))
    allocate(MissCountMatNotPhased(nAnisG))
    allocate(MissCountMatCorrect(nAnisG))
    allocate(HetCountMatWrong(nAnisG))
    allocate(HetCountMatNotPhased(nAnisG))
    allocate(HetCountMatCorrect(nAnisG))
    allocate(CountMatWrong(nAnisG))
    allocate(CountMatNotPhased(nAnisG))
    allocate(CountMatCorrect(nAnisG))
    allocate(MissCountPatWrong(nAnisG))
    allocate(MissCountPatNotPhased(nAnisG))
    allocate(MissCountPatCorrect(nAnisG))
    allocate(CountPatWrong(nAnisG))
    allocate(CountPatNotPhased(nAnisG))
    allocate(CountPatCorrect(nAnisG))
    allocate(ErrCountPatWrong(nAnisG))
    allocate(ErrCountPatNotPhased(nAnisG))
    allocate(ErrCountPatCorrect(nAnisG))
    allocate(holdPhase(totalSnps))

    print*, " "
    print*, " Checking simulation"
    print*, " "

    if (FullFileOutput==1) then
	if (WindowsLinux==1) then
		    write (filout,'(".\Simulation\IndivMistakes",i0,".txt")')OutputPoint
		    open (unit=17,FILE=filout,status='unknown')
		    write (filout,'(".\Simulation\Mistakes",i0,".txt")')OutputPoint
		    open (unit=18,FILE=filout,status='unknown')
		    write (filout,'(".\Simulation\IndivMistakesPercent",i0,".txt")')OutputPoint
		    open (unit=20,FILE=filout,status='unknown')
		    write (filout,'(".\Simulation\CoreMistakesPercent.txt")')
		    open (unit=31,FILE=filout,status='unknown',position='append')
	else
		    write (filout,'("./Simulation/IndivMistakes",i0,".txt")')OutputPoint
		    open (unit=17,FILE=filout,status='unknown')
		    write (filout,'("./Simulation/Mistakes",i0,".txt")')OutputPoint
		    open (unit=18,FILE=filout,status='unknown')
		    write (filout,'("./Simulation/IndivMistakesPercent",i0,".txt")')OutputPoint
		    open (unit=20,FILE=filout,status='unknown')
		    write (filout,'("./Simulation/CoreMistakesPercent.txt")')
		    open (unit=31,FILE=filout,status='unknown',position='append')
	endif
    end if

    open (unit = 16, file = trim(TruePhaseFile), status = "old")
      do i=1,nAnisG
	  read (16,*) dumC, holdPhase
	  TruePhase(i,:,1) = holdPhase(startSnp:endSnp)
	  read (16,*) dumC, holdPhase
	  TruePhase(i,:,2) = holdPhase(startSnp:endSnp)
      end do
    close(16)

    MistakePhase=9
    do i=1,nAnisG
	    CountPatNotPhased(i)=0
	    CountPatCorrect(i)=0
	    CountPatWrong(i)=0
	    HetCountPatNotPhased(i)=0
	    HetCountPatCorrect(i)=0
	    HetCountPatWrong(i)=0
	    MissCountPatNotPhased(i)=0
	    MissCountPatCorrect(i)=0
	    MissCountPatWrong(i)=0
	    ErrCountPatNotPhased(i)=0
	    ErrCountPatCorrect(i)=0
	    ErrCountPatWrong(i)=0

	    CountMatNotPhased(i)=0
	    CountMatCorrect(i)=0
	    CountMatWrong(i)=0
	    HetCountMatNotPhased(i)=0
	    HetCountMatCorrect(i)=0
	    HetCountMatWrong(i)=0
	    MissCountMatNotPhased(i)=0
	    MissCountMatCorrect(i)=0
	    MissCountMatWrong(i)=0
	    ErrCountMatNotPhased(i)=0
	    ErrCountMatCorrect(i)=0
	    ErrCountMatWrong(i)=0

	    do j=1,nSnp
		    if (c%getPhase(i,j,1)==9) then
			    MistakePhase(i,j,1)=9
			    CountPatNotPhased(i)=CountPatNotPhased(i)+1
			    if (c%getGeno(i,j)==1) then
				    HetCountPatNotPhased(i)=HetCountPatNotPhased(i)+1
			    end if
			    if (c%getGeno(i,j)==MissingGenotypeCode) then
				    MissCountPatNotPhased(i)=MissCountPatNotPhased(i)+1
			    end if
			    if ((c%getGeno(i,j)/=MissingGenotypeCode).and.((TruePhase(i,j,1)+TruePhase(i,j,2))/=c%getGeno(i,j))) then
				    ErrCountPatNotPhased(i)=ErrCountPatNotPhased(i)+1
			    end if


		    else
			if (TruePhase(i,j,1)==c%getPhase(i,j,1)) then
				    MistakePhase(i,j,1)=1
				    CountPatCorrect(i)=CountPatCorrect(i)+1
				    if (c%getGeno(i,j)==1) then
					    HetCountPatCorrect(i)=HetCountPatCorrect(i)+1
				end if
				    if (c%getGeno(i,j)==MissingGenotypeCode) then
					    MissCountPatCorrect(i)=MissCountPatCorrect(i)+1
				end if
				if ((c%getGeno(i,j)/=MissingGenotypeCode).and.((TruePhase(i,j,1)+TruePhase(i,j,2))/=c%getGeno(i,j))) then
					ErrCountPatCorrect(i)=ErrCountPatCorrect(i)+1
				end if
			    else
				    MistakePhase(i,j,1)=5
				    CountPatWrong(i)=CountPatWrong(i)+1
				    if (c%getGeno(i,j)==1) then
					    HetCountPatWrong(i)=HetCountPatWrong(i)+1
				end if
				    if (c%getGeno(i,j)==MissingGenotypeCode) then
					    MissCountPatWrong(i)=MissCountPatWrong(i)+1
				end if
				if ((c%getGeno(i,j)/=MissingGenotypeCode).and.((TruePhase(i,j,1)+TruePhase(i,j,2))/=c%getGeno(i,j))) then
					ErrCountPatWrong(i)=ErrCountPatWrong(i)+1
				end if

			end if
		    endif

		    if (c%getPhase(i,j,2)==9) then
			    MistakePhase(i,j,2)=9
			    CountMatNotPhased(i)=CountMatNotPhased(i)+1
			    if (c%getGeno(i,j)==1) then
				    HetCountMatNotPhased(i)=HetCountMatNotPhased(i)+1
			    end if
			    if (c%getGeno(i,j)==MissingGenotypeCode) then
				    MissCountMatNotPhased(i)=MissCountMatNotPhased(i)+1
			    end if
			    if ((c%getGeno(i,j)/=MissingGenotypeCode).and.((TruePhase(i,j,2)+TruePhase(i,j,1))/=c%getGeno(i,j))) then
				    ErrCountMatNotPhased(i)=ErrCountMatNotPhased(i)+1
			    end if
		    else
			if (TruePhase(i,j,2)==c%getPhase(i,j,2)) then
				    MistakePhase(i,j,2)=1
				    CountMatCorrect(i)=CountMatCorrect(i)+1
				    if (c%getGeno(i,j)==1) then
					    HetCountMatCorrect(i)=HetCountMatCorrect(i)+1
				end if
				    if (c%getGeno(i,j)==MissingGenotypeCode) then
					    MissCountMatCorrect(i)=MissCountMatCorrect(i)+1
				end if
				if ((c%getGeno(i,j)/=MissingGenotypeCode).and.((TruePhase(i,j,2)+TruePhase(i,j,1))/=c%getGeno(i,j))) then
					ErrCountMatCorrect(i)=ErrCountMatCorrect(i)+1
				end if
			    else
				    MistakePhase(i,j,2)=5
				    CountMatWrong(i)=CountMatWrong(i)+1
				    if (c%getGeno(i,j)==1) then
					    HetCountMatWrong(i)=HetCountMatWrong(i)+1
				end if
				    if (c%getGeno(i,j)==MissingGenotypeCode) then
					    MissCountMatWrong(i)=MissCountMatWrong(i)+1
				end if
				if ((c%getGeno(i,j)/=MissingGenotypeCode).and.((TruePhase(i,j,2)+TruePhase(i,j,1))/=c%getGeno(i,j))) then
					ErrCountMatWrong(i)=ErrCountMatWrong(i)+1
				end if

			end if
		    endif
	    end do
    PercCountPatCorrect(i)=100*(float(CountPatCorrect(i))/nSnp)
    PercCountMatCorrect(i)=100*(float(CountMatCorrect(i))/nSnp)
    PercCountPatNotPhased(i)=100*(float(CountPatNotPhased(i))/nSnp)
    PercCountMatNotPhased(i)=100*(float(CountMatNotPhased(i))/nSnp)
    PercCountPatWrong(i)=100*(float(CountPatWrong(i))/nSnp)
    PercCountMatWrong(i)=100*(float(CountMatWrong(i))/nSnp)
    PercHetCountPatCorrect(i)=100*(float(HetCountPatCorrect(i))&
		/(HetCountPatCorrect(i)+HetCountPatNotPhased(i)+HetCountPatWrong(i)+0.0000000001))
    PercHetCountMatCorrect(i)=100*(float(HetCountMatCorrect(i))&
		/(HetCountMatCorrect(i)+HetCountMatNotPhased(i)+HetCountMatWrong(i)+0.0000000001))
    PercHetCountPatNotPhased(i)=100*(float(HetCountPatNotPhased(i))&
		/(HetCountPatCorrect(i)+HetCountPatNotPhased(i)+HetCountPatWrong(i)+0.0000000001))
    PercHetCountMatNotPhased(i)=100*(float(HetCountMatNotPhased(i))&
		/(HetCountMatCorrect(i)+HetCountMatNotPhased(i)+HetCountMatWrong(i)+0.0000000001))
    PercHetCountPatWrong(i)=100*(float(HetCountPatWrong(i))&
		/(HetCountPatCorrect(i)+HetCountPatNotPhased(i)+HetCountPatWrong(i)+0.0000000001))
    PercHetCountMatWrong(i)=100*(float(HetCountMatWrong(i))&
		/(HetCountMatCorrect(i)+HetCountMatNotPhased(i)+HetCountMatWrong(i)+0.00000000001))
    PercMissCountPatCorrect(i)=&
	100*(float(MissCountPatCorrect(i))/(MissCountPatCorrect(i)+MissCountPatNotPhased(i)+MissCountPatWrong(i)+0.00000000001))
    PercMissCountMatCorrect(i)=&
	100*(float(MissCountMatCorrect(i))/(MissCountMatCorrect(i)+MissCountMatNotPhased(i)+MissCountMatWrong(i)+0.00000000001))
    PercMissCountPatNotPhased(i)=&
	100*(float(MissCountPatNotPhased(i))/(MissCountPatCorrect(i)+MissCountPatNotPhased(i)+MissCountPatWrong(i)+0.00000000001))
    PercMissCountMatNotPhased(i)=&
	100*(float(MissCountMatNotPhased(i))/(MissCountMatCorrect(i)+MissCountMatNotPhased(i)+MissCountMatWrong(i)+0.00000000001))
    PercMissCountPatWrong(i)=100*(float(MissCountPatWrong(i))&
		/(MissCountPatCorrect(i)+MissCountPatNotPhased(i)+MissCountPatWrong(i)+0.00000000001))
    PercMissCountMatWrong(i)=100*(float(MissCountMatWrong(i))&
		/(MissCountMatCorrect(i)+MissCountMatNotPhased(i)+MissCountMatWrong(i)+0.00000000001))
    PercErrCountPatCorrect(i)=100*(float(ErrCountPatCorrect(i))&
		/(ErrCountPatCorrect(i)+ErrCountPatNotPhased(i)+ErrCountPatWrong(i)+0.00000000001))
    PercErrCountMatCorrect(i)=100*(float(ErrCountMatCorrect(i))&
		/(ErrCountMatCorrect(i)+ErrCountMatNotPhased(i)+ErrCountMatWrong(i)+0.00000000001))
    PercErrCountPatNotPhased(i)=100*(float(ErrCountPatNotPhased(i))&
		/(ErrCountPatCorrect(i)+ErrCountPatNotPhased(i)+ErrCountPatWrong(i)+0.00000000001))
    PercErrCountMatNotPhased(i)=100*(float(ErrCountMatNotPhased(i))&
		/(ErrCountMatCorrect(i)+ErrCountMatNotPhased(i)+ErrCountMatWrong(i)+0.00000000001))
    PercErrCountPatWrong(i)=100*(float(ErrCountPatWrong(i))&
		/(ErrCountPatCorrect(i)+ErrCountPatNotPhased(i)+ErrCountPatWrong(i)+0.00000000001))
    PercErrCountMatWrong(i)=100*(float(ErrCountMatWrong(i))&
		/(ErrCountMatCorrect(i)+ErrCountMatNotPhased(i)+ErrCountMatWrong(i)+0.00000000001))

	    if (FullFileOutput==1) then
		nSurrogates=0
		do k=i,nAnisG
		    if (surrogates%numOppose(i,k)<=surrogates%threshold) nSurrogates=nSurrogates+1
		enddo
		write (17,'(a20,a3,3i5,a3,6i6,a6,6i6,a6,6i6,a6,6i6)') p%getID(i),"|",&
		     count(surrogates%partition(i,:)==1),count(surrogates%partition(i,:)==2),nSurrogates,"|",&
				CountPatCorrect(i),CountMatCorrect(i),CountPatNotPhased(i),&
				CountMatNotPhased(i),CountPatWrong(i),CountMatWrong(i),"|",&
					    HetCountPatCorrect(i),HetCountMatCorrect(i),HetCountPatNotPhased(i),&
				HetCountMatNotPhased(i),HetCountPatWrong(i),HetCountMatWrong(i),"|",&
					    MissCountPatCorrect(i),MissCountMatCorrect(i),MissCountPatNotPhased(i),&
				MissCountMatNotPhased(i),MissCountPatWrong(i),MissCountMatWrong(i),"|",&
					    ErrCountPatCorrect(i),ErrCountMatCorrect(i),ErrCountPatNotPhased(i),&
				ErrCountMatNotPhased(i),ErrCountPatWrong(i),ErrCountMatWrong(i)
		write (20,'(a20,a3,3i5,a3,6f7.1,a6,6f7.1,a6,6f7.1,a6,6f7.1)') p%getId(i),"|",&
		     count(surrogates%partition(i,:)==1),count(surrogates%partition(i,:)==2),nSurrogates,"|",&
				PercCountPatCorrect(i),PercCountMatCorrect(i),PercCountPatNotPhased(i),&
				PercCountMatNotPhased(i),PercCountPatWrong(i),PercCountMatWrong(i),"|",&
					    PercHetCountPatCorrect(i),PercHetCountMatCorrect(i),PercHetCountPatNotPhased(i),&
				PercHetCountMatNotPhased(i),PercHetCountPatWrong(i),PercHetCountMatWrong(i),"|",&
					    PercMissCountPatCorrect(i),PercMissCountMatCorrect(i),PercMissCountPatNotPhased(i),&
				PercMissCountMatNotPhased(i),PercMissCountPatWrong(i),PercMissCountMatWrong(i),"|",&
					    PercErrCountPatCorrect(i),PercErrCountMatCorrect(i),PercErrCountPatNotPhased(i),&
				PercErrCountMatNotPhased(i),PercErrCountPatWrong(i),PercErrCountMatWrong(i)

      write (18,'(a20,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3)') p%getID(i),&
	MistakePhase(i,:,1)
     write (18,'(a20,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3,20000i3)') p%getId(i),&
	MistakePhase(i,:,2)
	    endif

    end do

    print*, "   Summary statistics                               ","Paternal  Maternal"
    write (*,'(a40,a12,2f8.1)') "Percent correctly phased    All Snps"," ",&
			sum(PercCountPatCorrect(:))/nAnisG,sum(PercCountMatCorrect(:))/nAnisG
    write (*,'(a49,a3,2f8.1)') "Percent correctly phased    Heterozygous Snps"," ",sum(PercHetCountPatCorrect(:))/nAnisG&
					,sum(PercHetCountMatCorrect(:))/nAnisG
    write (*,*) " "
    write (*,'(a34,a18,2f8.1)') "Percent not phased    All Snps"," ",&
			sum(PercCountPatNotPhased(:))/nAnisG,sum(PercCountMatNotPhased(:))/nAnisG
    write (*,'(a43,a9,2f8.1)') "Percent not phased    Heterozygous Snps"," ",sum(PercHetCountPatNotPhased(:))/nAnisG&
					,sum(PercHetCountMatNotPhased(:))/nAnisG
    write (*,*) " "
    write (*,'(a42,a10,2f8.1)') "Percent incorrectly phased    All Snps"," ",&
			    sum(PercCountPatWrong(:))/nAnisG,sum(PercCountMatWrong(:))/nAnisG
    write (*,'(a51,a1,2f8.1)') "Percent incorrectly phased    Heterozygous Snps"," ",sum(PercHetCountPatWrong(:))/nAnisG&
					,sum(PercHetCountMatWrong(:))/nAnisG

    if (FullFileOutput==1) then 
      write (31,'(6f9.4)') (sum(PercCountPatCorrect(:))+sum(PercCountMatCorrect(:)))/(2*nAnisG),&
		(sum(PercHetCountPatCorrect(:))+sum(PercHetCountMatCorrect(:)))/(2*nAnisG),&
			    (sum(PercCountPatNotPhased(:))+sum(PercCountMatNotPhased(:)))/(2*nAnisG),&
			    (sum(PercHetCountPatNotPhased(:))+sum(PercHetCountMatNotPhased(:)))/(2*nAnisG),&
			    (sum(PercCountPatWrong(:))+sum(PercCountMatWrong(:)))/(2*nAnisG),&
			    (sum(PercHetCountPatWrong(:))+sum(PercHetCountMatWrong(:)))/(2*nAnisG)
			    
      close(17)
      close(18)
      close(20)
      close(31)
    endif    


!!! THIS SHOULD GO ELSEWHERE!!!
!    if (OutputPoint==nCores) then
!	if (FullFileOutput==1) then 
!	    rewind(31)
!	    do i=1,nCores
!		    read (31,*) AverageMatrix(i,:)
!	    end do
!	    write (31,*) " "
!	    write (31,'(6f9.4)') sum(AverageMatrix(:,1))/nCores,sum(AverageMatrix(:,2))/nCores,sum(AverageMatrix(:,3))/nCores,&
!			sum(AverageMatrix(:,4))/nCores,sum(AverageMatrix(:,5))/nCores,sum(AverageMatrix(:,6))/nCores
!	endif
!    end if

  end subroutine Checker
  
  subroutine CheckerCombine(nCores)
    use Parameters, only: FullFileOutput
    use Constants
    
    integer, intent(in) :: nCores

    character(len=300) :: filout    
    double precision,allocatable,dimension(:,:) :: AverageMatrix
    
    allocate(AverageMatrix(nCores,6))
    
    if (FullFileOutput==1) then
	if (WindowsLinux==1) then
	  write (filout,'(".\Simulation\CoreMistakesPercent.txt")')
	  open (unit=31,FILE=filout,status='unknown')
	else
	  write (filout,'("./Simulation/CoreMistakesPercent.txt")')
	  open (unit=31,FILE=filout,status='unknown')
	endif
	do i=1,nCores
		read (31,*) AverageMatrix(i,:)
	end do
	write (31,*) " "
	write (31,'(6f9.4)') sum(AverageMatrix(:,1))/nCores,sum(AverageMatrix(:,2))/nCores,sum(AverageMatrix(:,3))/nCores,&
		    sum(AverageMatrix(:,4))/nCores,sum(AverageMatrix(:,5))/nCores,sum(AverageMatrix(:,6))/nCores
    endif
  end subroutine CheckerCombine
end module Testing

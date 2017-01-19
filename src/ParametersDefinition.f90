module ParametersDefinition
  implicit none
  private
  
  type, public:: Parameters
    character(len=300) GenotypeFile
    integer :: GenotypeFileFormat
    integer :: nSnp   ! Possibly doesn't need to be a parameter  
    integer :: CoreAndTailLength
    integer :: Jump
    logical :: Offset
    integer :: UseSurrsN
    integer :: NumSurrDisagree
    double precision :: PercGenoHaploDisagree
    double precision :: GenotypeMissingErrorPercentage
    logical :: Simulation
    character (len = 300) :: PedigreeFile, TruePhaseFile, Library

    character (len = 300) :: itterateType
    integer :: itterateNumber
    integer :: numIter
    character (len = 10) :: startCoreChar, endCoreChar
    integer :: minHapFreq
    
    integer :: nChips
    character(len = 300) :: ChipsSnps, ChipsAnimals
       
    logical :: outputFinalPhase
    logical :: outputCoreIndex
    logical :: outputSnpPhaseRate
    logical :: outputIndivPhaseRate
    logical :: outputHapIndex
    logical :: outputSwappable
    logical :: outputHapCommonality
    logical :: outputSurrogates
    logical :: outputSurrogatesSummary
    logical :: outputHaplotypeLibraryText
    logical :: outputHaplotypeLibraryBinary
    logical :: outputPhasingYield
    logical :: outputTimer
    logical :: outputIndivMistakes
    logical :: outputIndivMistakesPercent
    logical :: outputCoreMistakesPercent
    logical :: outputMistakes
    
  end type Parameters

  interface Parameters
    module procedure newParameters
  end interface Parameters
  
contains
  function newParameters result(params)
    type(Parameters) :: params
    !!! DEFAULT VALUES !!!
    params%itterateType = "Off"
    params%itterateNumber = 200
    params%numIter = 1
    params%startCoreChar = "1"
    params%endCoreChar = "Combine"
    params%minHapFreq = 1
    params%library = "None"
  end function newParameters
    
end module ParametersDefinition
module ParametersDefinition
  implicit none
  
  type:: Parameters
    integer :: CoreAndTailLength
    integer :: Jump
    logical :: Offset
    integer :: UseSurrsN
    integer :: NumSurrDisagree
    double precision :: PercGenoHaploDisagree
    double precision :: GenotypeMissingErrorPercentage

    character (len = 300) :: itterateType
    integer :: itterateNumber
    integer :: numIter
    character (len = 10) :: startCoreChar, endCoreChar
    integer :: minHapFreq
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
  end function newParameters
    
end module ParametersDefinition
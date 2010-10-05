!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade 3.3 (r3163) - 09/25/2009 09:03
!
!  Differentiation of computeforcecouplingpressureadj in reverse (adjoint) mode:
!   gradient, with respect to input variables: gammaconstant wadj
!   of linear combination of output variables: padj
!
!      ******************************************************************
!      *                                                                *
!      * File:          computeForcesPressureAdj.f90                    *
!      * Author:        Edwin van der Weide,C.A.(Sandy) Mader           *
!      * Starting date: 03-19-2006                                      *
!      * Last modified: 05-06-2008                                      *
!      *                                                                *
!      ******************************************************************
!
SUBROUTINE COMPUTEFORCECOUPLINGPRESSUREADJ_B(wadj, wadjb, padj, padjb)
  USE INPUTPHYSICS
  USE FLOWVARREFSTATE
  IMPLICIT NONE
!
!      ******************************************************************
!      *                                                                *
!      * Simple routine to compute the pressure from the variables w.   *
!      * A calorically perfect gas, i.e. constant gamma, is assumed.    *
!      *                                                                *
!      ******************************************************************
!
!
!      Subroutine arguments
!
  REAL(kind=realtype), DIMENSION(2, 2, 2, nw), INTENT(IN) :: wadj
  REAL(kind=realtype), DIMENSION(2, 2, 2, nw) :: wadjb
  REAL(kind=realtype), DIMENSION(2, 2, 2) :: padj
  REAL(kind=realtype), DIMENSION(2, 2, 2) :: padjb
!
!      Local variables
!
  INTEGER(kind=inttype) :: i, j, k
  REAL(kind=realtype) :: gm1, factk, v2
  REAL(kind=realtype) :: v2b
  REAL(kind=realtype) :: tempb0
  REAL(kind=realtype) :: tempb
!      ******************************************************************
!      *                                                                *
!      * Begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
  gm1 = gammaconstant - one
! Check the situation.
  IF (kpresent) THEN
! A separate equation for the turbulent kinetic energy is
! present. This variable must be taken into account.
    factk = five*third - gammaconstant
    DO k=1,2
      DO j=1,2
        DO i=1,2
          CALL PUSHREAL8ARRAY(v2, realtype/8)
          v2 = wadj(i, j, k, ivx)**2 + wadj(i, j, k, ivy)**2 + wadj(i, j&
&            , k, ivz)**2
        END DO
      END DO
    END DO
    wadjb = 0.0
    DO k=2,1,-1
      DO j=2,1,-1
        DO i=2,1,-1
          tempb = gm1*padjb(i, j, k)
          wadjb(i, j, k, irhoe) = wadjb(i, j, k, irhoe) + tempb
          wadjb(i, j, k, irho) = wadjb(i, j, k, irho) + factk*wadj(i, j&
&            , k, itu1)*padjb(i, j, k) - half*v2*tempb
          v2b = -(half*wadj(i, j, k, irho)*tempb)
          wadjb(i, j, k, itu1) = wadjb(i, j, k, itu1) + factk*wadj(i, j&
&            , k, irho)*padjb(i, j, k)
          padjb(i, j, k) = 0.0
          CALL POPREAL8ARRAY(v2, realtype/8)
          wadjb(i, j, k, ivx) = wadjb(i, j, k, ivx) + 2*wadj(i, j, k, &
&            ivx)*v2b
          wadjb(i, j, k, ivy) = wadjb(i, j, k, ivy) + 2*wadj(i, j, k, &
&            ivy)*v2b
          wadjb(i, j, k, ivz) = wadjb(i, j, k, ivz) + 2*wadj(i, j, k, &
&            ivz)*v2b
        END DO
      END DO
    END DO
  ELSE
! No separate equation for the turbulent kinetic enery.
! Use the standard formula.
    DO k=1,2
      DO j=1,2
        DO i=1,2
          CALL PUSHREAL8ARRAY(v2, realtype/8)
          v2 = wadj(i, j, k, ivx)**2 + wadj(i, j, k, ivy)**2 + wadj(i, j&
&            , k, ivz)**2
        END DO
      END DO
    END DO
    wadjb = 0.0
    DO k=2,1,-1
      DO j=2,1,-1
        DO i=2,1,-1
          tempb0 = gm1*padjb(i, j, k)
          wadjb(i, j, k, irhoe) = wadjb(i, j, k, irhoe) + tempb0
          wadjb(i, j, k, irho) = wadjb(i, j, k, irho) - half*v2*tempb0
          v2b = -(half*wadj(i, j, k, irho)*tempb0)
          padjb(i, j, k) = 0.0
          CALL POPREAL8ARRAY(v2, realtype/8)
          wadjb(i, j, k, ivx) = wadjb(i, j, k, ivx) + 2*wadj(i, j, k, &
&            ivx)*v2b
          wadjb(i, j, k, ivy) = wadjb(i, j, k, ivy) + 2*wadj(i, j, k, &
&            ivy)*v2b
          wadjb(i, j, k, ivz) = wadjb(i, j, k, ivz) + 2*wadj(i, j, k, &
&            ivz)*v2b
        END DO
      END DO
    END DO
  END IF
  gammaconstantb = 0.0
END SUBROUTINE COMPUTEFORCECOUPLINGPRESSUREADJ_B

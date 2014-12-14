   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of sasolve in forward (tangent) mode (with options i4 dr8 r8):
   !   variations   of useful results: *dw
   !   with respect to varying inputs: *sfacei *sfacej *sfacek *dw
   !                *w *rlv *vol *si *sj *sk (global)timeref
   !   Plus diff mem management of: sfacei:in sfacej:in sfacek:in
   !                dw:in w:in rlv:in vol:in si:in sj:in sk:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          saSolve.f90                                     *
   !      * Author:        Georgi Kalitzin, Edwin van der Weide,           *
   !      *                Steve Repsher (blanking)                        *
   !      * Starting date: 06-11-2003                                      *
   !      * Last modified: 07-05-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE SASOLVE_D(resonly)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * saSolve solves the turbulent transport equation for the        *
   !      * original Spalart-Allmaras model in a segregated manner using   *
   !      * a diagonal dominant ADI-scheme.                                *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BCTYPES
   USE BLOCKPOINTERS_D
   USE CONSTANTS
   USE INPUTITERATION
   USE INPUTPHYSICS
   USE PARAMTURB
   USE TURBMOD
   IMPLICIT NONE
   ! Don't need the remainder for residual derivative
   !
   !      Subroutine arguments.
   !
   LOGICAL, INTENT(IN) :: resonly
   !
   !      Local parameters.
   !
   REAL(kind=realtype), PARAMETER :: xminn=1.e-10_realType
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: i, j, k, nn
   REAL(kind=realtype) :: cv13, kar2inv, cw36, cb3inv
   REAL(kind=realtype) :: fv1, fv2, ft2
   REAL(kind=realtype) :: fv1d, fv2d, ft2d
   REAL(kind=realtype) :: ss, sst, nu, dist2inv, chi, chi2, chi3
   REAL(kind=realtype) :: ssd, sstd, nud, chid, chi2d, chi3d
   REAL(kind=realtype) :: rr, gg, gg6, termfw, fwsa, term1, term2
   REAL(kind=realtype) :: rrd, ggd, gg6d, termfwd, fwsad, term1d, term2d
   REAL(kind=realtype) :: dfv1, dfv2, dft2, drr, dgg, dfw
   REAL(kind=realtype) :: voli, volmi, volpi, xm, ym, zm, xp, yp, zp
   REAL(kind=realtype) :: volid, volmid, volpid, xmd, ymd, zmd, xpd, ypd&
   & , zpd
   REAL(kind=realtype) :: xa, ya, za, ttm, ttp, cnud, cam, cap
   REAL(kind=realtype) :: xad, yad, zad, ttmd, ttpd, cnudd, camd, capd
   REAL(kind=realtype) :: nutm, nutp, num, nup, cdm, cdp
   REAL(kind=realtype) :: nutmd, nutpd, numd, nupd, cdmd, cdpd
   REAL(kind=realtype) :: c1m, c1p, c10, b1, c1, d1, qs
   REAL(kind=realtype) :: c1md, c1pd, c10d
   REAL(kind=realtype) :: uu, um, up, factor, f, tu1p, rblank
   REAL(kind=realtype), DIMENSION(2:il, 2:jl, 2:kl) :: qq
   REAL(kind=realtype), DIMENSION(2:MAX(kl, il, jl)) :: bb, cc, dd, ff
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ddw, ww, ddvt
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rrlv
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: dd2wall
   LOGICAL, DIMENSION(2:jl, 2:kl), TARGET :: flagi2, flagil
   LOGICAL, DIMENSION(2:il, 2:kl), TARGET :: flagj2, flagjl
   LOGICAL, DIMENSION(2:il, 2:jl), TARGET :: flagk2, flagkl
   LOGICAL, DIMENSION(:, :), POINTER :: flag
   INTRINSIC MAX
   INTRINSIC SQRT
   INTRINSIC EXP
   INTRINSIC MIN
   INTRINSIC REAL
   REAL(kind=realtype) :: pwx1
   REAL(kind=realtype) :: pwx1d
   REAL(kind=realtype) :: max6
   REAL(kind=realtype) :: max5
   REAL(kind=realtype) :: max4
   REAL(kind=realtype) :: max3
   REAL(kind=realtype) :: max2
   REAL(kind=realtype) :: max1
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Set model constants
   cv13 = rsacv1**3
   kar2inv = one/rsak**2
   cw36 = rsacw3**6
   cb3inv = one/rsacb3
   ! Set the pointer for dvt in dw, such that the code is more
   ! readable. Also set the pointers for the production term
   ! and vorticity.
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Production term.                                               *
   !      *                                                                *
   !      ******************************************************************
   !
   SELECT CASE  (turbprod) 
   CASE (strain) 
   CALL PRODSMAG2_D()
   CASE (vorticity) 
   CALL PRODWMAG2_D()
   CASE (katolaunder) 
   CALL PRODKATOLAUNDER_D()
   END SELECT
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Source terms.                                                  *
   !      *                                                                *
   !      * Determine the source term and its derivative w.r.t. nuTilde    *
   !      * for all internal cells of the block.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   ! First take the square root of the production term to
   ! obtain the correct production term for spalart-allmaras.
   IF (dw(i, j, k, iprod) .EQ. 0.0_8) THEN
   ssd = 0.0_8
   ELSE
   ssd = dwd(i, j, k, iprod)/(2.0*SQRT(dw(i, j, k, iprod)))
   END IF
   ss = SQRT(dw(i, j, k, iprod))
   ! Compute the laminar kinematic viscosity, the inverse of
   ! wall distance squared, the ratio chi (ratio of nuTilde
   ! and nu) and the functions fv1 and fv2. The latter corrects
   ! the production term near a viscous wall.
   nud = (rlvd(i, j, k)*w(i, j, k, irho)-rlv(i, j, k)*wd(i, j, k, &
   &         irho))/w(i, j, k, irho)**2
   nu = rlv(i, j, k)/w(i, j, k, irho)
   dist2inv = one/d2wall(i, j, k)**2
   chid = (wd(i, j, k, itu1)*nu-w(i, j, k, itu1)*nud)/nu**2
   chi = w(i, j, k, itu1)/nu
   chi2d = chid*chi + chi*chid
   chi2 = chi*chi
   chi3d = chid*chi2 + chi*chi2d
   chi3 = chi*chi2
   fv1d = (chi3d*(chi3+cv13)-chi3*chi3d)/(chi3+cv13)**2
   fv1 = chi3/(chi3+cv13)
   fv2d = -((chid*(one+chi*fv1)-chi*(chid*fv1+chi*fv1d))/(one+chi*&
   &         fv1)**2)
   fv2 = one - chi/(one+chi*fv1)
   ! The function ft2, which is designed to keep a laminar
   ! solution laminar. When running in fully turbulent mode
   ! this function should be set to 0.0.
   ft2d = -(rsact3*rsact4*chi2d*EXP(-(rsact4*chi2)))
   ft2 = rsact3*EXP(-(rsact4*chi2))
   ! ft2 = zero
   ! Correct the production term to account for the influence
   ! of the wall. Make sure that this term remains positive
   ! (the function fv2 is negative between chi = 1 and 18.4,
   ! which can cause sst to go negative, which is undesirable).
   sstd = ssd + kar2inv*dist2inv*(wd(i, j, k, itu1)*fv2+w(i, j, k, &
   &         itu1)*fv2d)
   sst = ss + w(i, j, k, itu1)*fv2*kar2inv*dist2inv
   IF (sst .LT. xminn) THEN
   sst = xminn
   sstd = 0.0_8
   ELSE
   sst = sst
   END IF
   ! Compute the function fw. The argument rr is cut off at 10
   ! to avoid numerical problems. This is ok, because the
   ! asymptotical value of fw is then already reached.
   rrd = (kar2inv*dist2inv*wd(i, j, k, itu1)*sst-w(i, j, k, itu1)*&
   &         kar2inv*dist2inv*sstd)/sst**2
   rr = w(i, j, k, itu1)*kar2inv*dist2inv/sst
   IF (rr .GT. 10.0_realType) THEN
   rr = 10.0_realType
   rrd = 0.0_8
   ELSE
   rr = rr
   END IF
   ggd = rrd + rsacw2*(6*rr**5*rrd-rrd)
   gg = rr + rsacw2*(rr**6-rr)
   gg6d = 6*gg**5*ggd
   gg6 = gg**6
   pwx1d = -((one+cw36)*gg6d/(gg6+cw36)**2)
   pwx1 = (one+cw36)/(gg6+cw36)
   IF (pwx1 .GT. 0.0_8 .OR. (pwx1 .LT. 0.0_8 .AND. sixth .EQ. INT(&
   &           sixth))) THEN
   termfwd = sixth*pwx1**(sixth-1)*pwx1d
   ELSE IF (pwx1 .EQ. 0.0_8 .AND. sixth .EQ. 1.0) THEN
   termfwd = pwx1d
   ELSE
   termfwd = 0.0_8
   END IF
   termfw = pwx1**sixth
   fwsad = ggd*termfw + gg*termfwd
   fwsa = gg*termfw
   ! Compute the source term; some terms are saved for the
   ! linearization. The source term is stored in dvt.
   term1d = rsacb1*((one-ft2)*ssd-ft2d*ss)
   term1 = rsacb1*(one-ft2)*ss
   term2d = dist2inv*(kar2inv*rsacb1*((one-ft2)*fv2d-ft2d*fv2+ft2d)&
   &         -rsacw1*fwsad)
   term2 = dist2inv*(kar2inv*rsacb1*((one-ft2)*fv2+ft2)-rsacw1*fwsa&
   &         )
   dwd(i, j, k, idvt) = (term1d+term2d*w(i, j, k, itu1)+term2*wd(i&
   &         , j, k, itu1))*w(i, j, k, itu1) + (term1+term2*w(i, j, k, itu1&
   &         ))*wd(i, j, k, itu1)
   dw(i, j, k, idvt) = (term1+term2*w(i, j, k, itu1))*w(i, j, k, &
   &         itu1)
   ! Compute some derivatives w.r.t. nuTilde. These will occur
   ! in the left hand side, i.e. the matrix for the implicit
   ! treatment.
   dfv1 = three*chi2*cv13/(chi3+cv13)**2
   dfv2 = (chi2*dfv1-one)/(nu*(one+chi*fv1)**2)
   dft2 = -(two*rsact4*chi*ft2/nu)
   drr = (one-rr*(fv2+w(i, j, k, itu1)*dfv2))*kar2inv*dist2inv/sst
   dgg = (one-rsacw2+six*rsacw2*rr**5)*drr
   dfw = cw36/(gg6+cw36)*termfw*dgg
   ! Compute the source term jacobian. Note that the part
   ! containing term1 is treated explicitly. The reason is that
   ! implicit treatment of this part leads to a decrease of the
   ! diagonal dominance of the jacobian and it thus decreases
   ! the stability. You may want to play around and try to
   ! take this term into account in the jacobian.
   ! Note that -dsource/dnu is stored.
   qq(i, j, k) = -(two*term2*w(i, j, k, itu1)) - dist2inv*w(i, j, k&
   &         , itu1)*w(i, j, k, itu1)*(rsacb1*kar2inv*(dfv2-ft2*dfv2-fv2*&
   &         dft2+dft2)-rsacw1*dfw)
   IF (qq(i, j, k) .LT. zero) THEN
   qq(i, j, k) = zero
   ELSE
   qq(i, j, k) = qq(i, j, k)
   END IF
   END DO
   END DO
   END DO
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Advection and unsteady terms.                                  *
   !      *                                                                *
   !      ******************************************************************
   !
   nn = itu1 - 1
   CALL TURBADVECTION_D(1_intType, 1_intType, nn, qq)
   CALL UNSTEADYTURBTERM_D(1_intType, 1_intType, nn, qq)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Viscous terms in k-direction.                                  *
   !      *                                                                *
   !      ******************************************************************
   !
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   ! Compute the metrics in zeta-direction, i.e. along the
   ! line k = constant.
   volid = -(one*vold(i, j, k)/vol(i, j, k)**2)
   voli = one/vol(i, j, k)
   volmid = -(two*(vold(i, j, k)+vold(i, j, k-1))/(vol(i, j, k)+vol&
   &         (i, j, k-1))**2)
   volmi = two/(vol(i, j, k)+vol(i, j, k-1))
   volpid = -(two*(vold(i, j, k)+vold(i, j, k+1))/(vol(i, j, k)+vol&
   &         (i, j, k+1))**2)
   volpi = two/(vol(i, j, k)+vol(i, j, k+1))
   xmd = skd(i, j, k-1, 1)*volmi + sk(i, j, k-1, 1)*volmid
   xm = sk(i, j, k-1, 1)*volmi
   ymd = skd(i, j, k-1, 2)*volmi + sk(i, j, k-1, 2)*volmid
   ym = sk(i, j, k-1, 2)*volmi
   zmd = skd(i, j, k-1, 3)*volmi + sk(i, j, k-1, 3)*volmid
   zm = sk(i, j, k-1, 3)*volmi
   xpd = skd(i, j, k, 1)*volpi + sk(i, j, k, 1)*volpid
   xp = sk(i, j, k, 1)*volpi
   ypd = skd(i, j, k, 2)*volpi + sk(i, j, k, 2)*volpid
   yp = sk(i, j, k, 2)*volpi
   zpd = skd(i, j, k, 3)*volpi + sk(i, j, k, 3)*volpid
   zp = sk(i, j, k, 3)*volpi
   xad = half*((skd(i, j, k, 1)+skd(i, j, k-1, 1))*voli+(sk(i, j, k&
   &         , 1)+sk(i, j, k-1, 1))*volid)
   xa = half*(sk(i, j, k, 1)+sk(i, j, k-1, 1))*voli
   yad = half*((skd(i, j, k, 2)+skd(i, j, k-1, 2))*voli+(sk(i, j, k&
   &         , 2)+sk(i, j, k-1, 2))*volid)
   ya = half*(sk(i, j, k, 2)+sk(i, j, k-1, 2))*voli
   zad = half*((skd(i, j, k, 3)+skd(i, j, k-1, 3))*voli+(sk(i, j, k&
   &         , 3)+sk(i, j, k-1, 3))*volid)
   za = half*(sk(i, j, k, 3)+sk(i, j, k-1, 3))*voli
   ttmd = xmd*xa + xm*xad + ymd*ya + ym*yad + zmd*za + zm*zad
   ttm = xm*xa + ym*ya + zm*za
   ttpd = xpd*xa + xp*xad + ypd*ya + yp*yad + zpd*za + zp*zad
   ttp = xp*xa + yp*ya + zp*za
   ! Computation of the viscous terms in zeta-direction; note
   ! that cross-derivatives are neglected, i.e. the mesh is
   ! assumed to be orthogonal.
   ! Furthermore, the grad(nu)**2 has been rewritten as
   ! div(nu grad(nu)) - nu div(grad nu) to enhance stability.
   ! The second derivative in zeta-direction is constructed as
   ! the central difference of the first order derivatives, i.e.
   ! d^2/dzeta^2 = d/dzeta (d/dzeta k+1/2 - d/dzeta k-1/2).
   ! In this way the metric can be taken into account.
   ! Compute the diffusion coefficients multiplying the nodes
   ! k+1, k and k-1 in the second derivative. Make sure that
   ! these coefficients are nonnegative.
   cnudd = -(rsacb2*cb3inv*wd(i, j, k, itu1))
   cnud = -(rsacb2*w(i, j, k, itu1)*cb3inv)
   camd = ttmd*cnud + ttm*cnudd
   cam = ttm*cnud
   capd = ttpd*cnud + ttp*cnudd
   cap = ttp*cnud
   nutmd = half*(wd(i, j, k-1, itu1)+wd(i, j, k, itu1))
   nutm = half*(w(i, j, k-1, itu1)+w(i, j, k, itu1))
   nutpd = half*(wd(i, j, k+1, itu1)+wd(i, j, k, itu1))
   nutp = half*(w(i, j, k+1, itu1)+w(i, j, k, itu1))
   nud = (rlvd(i, j, k)*w(i, j, k, irho)-rlv(i, j, k)*wd(i, j, k, &
   &         irho))/w(i, j, k, irho)**2
   nu = rlv(i, j, k)/w(i, j, k, irho)
   numd = half*((rlvd(i, j, k-1)*w(i, j, k-1, irho)-rlv(i, j, k-1)*&
   &         wd(i, j, k-1, irho))/w(i, j, k-1, irho)**2+nud)
   num = half*(rlv(i, j, k-1)/w(i, j, k-1, irho)+nu)
   nupd = half*((rlvd(i, j, k+1)*w(i, j, k+1, irho)-rlv(i, j, k+1)*&
   &         wd(i, j, k+1, irho))/w(i, j, k+1, irho)**2+nud)
   nup = half*(rlv(i, j, k+1)/w(i, j, k+1, irho)+nu)
   cdmd = cb3inv*((numd+(one+rsacb2)*nutmd)*ttm+(num+(one+rsacb2)*&
   &         nutm)*ttmd)
   cdm = (num+(one+rsacb2)*nutm)*ttm*cb3inv
   cdpd = cb3inv*((nupd+(one+rsacb2)*nutpd)*ttp+(nup+(one+rsacb2)*&
   &         nutp)*ttpd)
   cdp = (nup+(one+rsacb2)*nutp)*ttp*cb3inv
   IF (cdm + cam .LT. zero) THEN
   c1m = zero
   c1md = 0.0_8
   ELSE
   c1md = cdmd + camd
   c1m = cdm + cam
   END IF
   IF (cdp + cap .LT. zero) THEN
   c1p = zero
   c1pd = 0.0_8
   ELSE
   c1pd = cdpd + capd
   c1p = cdp + cap
   END IF
   c10d = c1md + c1pd
   c10 = c1m + c1p
   ! Update the residual for this cell and store the possible
   ! coefficients for the matrix in b1, c1 and d1.
   dwd(i, j, k, idvt) = dwd(i, j, k, idvt) + c1md*w(i, j, k-1, itu1&
   &         ) + c1m*wd(i, j, k-1, itu1) - c10d*w(i, j, k, itu1) - c10*wd(i&
   &         , j, k, itu1) + c1pd*w(i, j, k+1, itu1) + c1p*wd(i, j, k+1, &
   &         itu1)
   dw(i, j, k, idvt) = dw(i, j, k, idvt) + c1m*w(i, j, k-1, itu1) -&
   &         c10*w(i, j, k, itu1) + c1p*w(i, j, k+1, itu1)
   b1 = -c1m
   c1 = c10
   d1 = -c1p
   ! Update the central jacobian. For nonboundary cells this
   ! is simply c1. For boundary cells this is slightly more
   ! complicated, because the boundary conditions are treated
   ! implicitly and the off-diagonal terms b1 and d1 must be
   ! taken into account.
   ! The boundary conditions are only treated implicitly if
   ! the diagonal dominance of the matrix is increased.
   IF (k .EQ. 2) THEN
   IF (bmtk1(i, j, itu1, itu1) .LT. zero) THEN
   max1 = zero
   ELSE
   max1 = bmtk1(i, j, itu1, itu1)
   END IF
   qq(i, j, k) = qq(i, j, k) + c1 - b1*max1
   ELSE IF (k .EQ. kl) THEN
   IF (bmtk2(i, j, itu1, itu1) .LT. zero) THEN
   max2 = zero
   ELSE
   max2 = bmtk2(i, j, itu1, itu1)
   END IF
   qq(i, j, k) = qq(i, j, k) + c1 - d1*max2
   ELSE
   qq(i, j, k) = qq(i, j, k) + c1
   END IF
   END DO
   END DO
   END DO
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Viscous terms in j-direction.                                  *
   !      *                                                                *
   !      ******************************************************************
   !
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   ! Compute the metrics in eta-direction, i.e. along the
   ! line j = constant.
   volid = -(one*vold(i, j, k)/vol(i, j, k)**2)
   voli = one/vol(i, j, k)
   volmid = -(two*(vold(i, j, k)+vold(i, j-1, k))/(vol(i, j, k)+vol&
   &         (i, j-1, k))**2)
   volmi = two/(vol(i, j, k)+vol(i, j-1, k))
   volpid = -(two*(vold(i, j, k)+vold(i, j+1, k))/(vol(i, j, k)+vol&
   &         (i, j+1, k))**2)
   volpi = two/(vol(i, j, k)+vol(i, j+1, k))
   xmd = sjd(i, j-1, k, 1)*volmi + sj(i, j-1, k, 1)*volmid
   xm = sj(i, j-1, k, 1)*volmi
   ymd = sjd(i, j-1, k, 2)*volmi + sj(i, j-1, k, 2)*volmid
   ym = sj(i, j-1, k, 2)*volmi
   zmd = sjd(i, j-1, k, 3)*volmi + sj(i, j-1, k, 3)*volmid
   zm = sj(i, j-1, k, 3)*volmi
   xpd = sjd(i, j, k, 1)*volpi + sj(i, j, k, 1)*volpid
   xp = sj(i, j, k, 1)*volpi
   ypd = sjd(i, j, k, 2)*volpi + sj(i, j, k, 2)*volpid
   yp = sj(i, j, k, 2)*volpi
   zpd = sjd(i, j, k, 3)*volpi + sj(i, j, k, 3)*volpid
   zp = sj(i, j, k, 3)*volpi
   xad = half*((sjd(i, j, k, 1)+sjd(i, j-1, k, 1))*voli+(sj(i, j, k&
   &         , 1)+sj(i, j-1, k, 1))*volid)
   xa = half*(sj(i, j, k, 1)+sj(i, j-1, k, 1))*voli
   yad = half*((sjd(i, j, k, 2)+sjd(i, j-1, k, 2))*voli+(sj(i, j, k&
   &         , 2)+sj(i, j-1, k, 2))*volid)
   ya = half*(sj(i, j, k, 2)+sj(i, j-1, k, 2))*voli
   zad = half*((sjd(i, j, k, 3)+sjd(i, j-1, k, 3))*voli+(sj(i, j, k&
   &         , 3)+sj(i, j-1, k, 3))*volid)
   za = half*(sj(i, j, k, 3)+sj(i, j-1, k, 3))*voli
   ttmd = xmd*xa + xm*xad + ymd*ya + ym*yad + zmd*za + zm*zad
   ttm = xm*xa + ym*ya + zm*za
   ttpd = xpd*xa + xp*xad + ypd*ya + yp*yad + zpd*za + zp*zad
   ttp = xp*xa + yp*ya + zp*za
   ! Computation of the viscous terms in eta-direction; note
   ! that cross-derivatives are neglected, i.e. the mesh is
   ! assumed to be orthogonal.
   ! Furthermore, the grad(nu)**2 has been rewritten as
   ! div(nu grad(nu)) - nu div(grad nu) to enhance stability.
   ! The second derivative in eta-direction is constructed as
   ! the central difference of the first order derivatives, i.e.
   ! d^2/deta^2 = d/deta (d/deta j+1/2 - d/deta j-1/2).
   ! In this way the metric can be taken into account.
   ! Compute the diffusion coefficients multiplying the nodes
   ! j+1, j and j-1 in the second derivative. Make sure that
   ! these coefficients are nonnegative.
   cnudd = -(rsacb2*cb3inv*wd(i, j, k, itu1))
   cnud = -(rsacb2*w(i, j, k, itu1)*cb3inv)
   camd = ttmd*cnud + ttm*cnudd
   cam = ttm*cnud
   capd = ttpd*cnud + ttp*cnudd
   cap = ttp*cnud
   nutmd = half*(wd(i, j-1, k, itu1)+wd(i, j, k, itu1))
   nutm = half*(w(i, j-1, k, itu1)+w(i, j, k, itu1))
   nutpd = half*(wd(i, j+1, k, itu1)+wd(i, j, k, itu1))
   nutp = half*(w(i, j+1, k, itu1)+w(i, j, k, itu1))
   nud = (rlvd(i, j, k)*w(i, j, k, irho)-rlv(i, j, k)*wd(i, j, k, &
   &         irho))/w(i, j, k, irho)**2
   nu = rlv(i, j, k)/w(i, j, k, irho)
   numd = half*((rlvd(i, j-1, k)*w(i, j-1, k, irho)-rlv(i, j-1, k)*&
   &         wd(i, j-1, k, irho))/w(i, j-1, k, irho)**2+nud)
   num = half*(rlv(i, j-1, k)/w(i, j-1, k, irho)+nu)
   nupd = half*((rlvd(i, j+1, k)*w(i, j+1, k, irho)-rlv(i, j+1, k)*&
   &         wd(i, j+1, k, irho))/w(i, j+1, k, irho)**2+nud)
   nup = half*(rlv(i, j+1, k)/w(i, j+1, k, irho)+nu)
   cdmd = cb3inv*((numd+(one+rsacb2)*nutmd)*ttm+(num+(one+rsacb2)*&
   &         nutm)*ttmd)
   cdm = (num+(one+rsacb2)*nutm)*ttm*cb3inv
   cdpd = cb3inv*((nupd+(one+rsacb2)*nutpd)*ttp+(nup+(one+rsacb2)*&
   &         nutp)*ttpd)
   cdp = (nup+(one+rsacb2)*nutp)*ttp*cb3inv
   IF (cdm + cam .LT. zero) THEN
   c1m = zero
   c1md = 0.0_8
   ELSE
   c1md = cdmd + camd
   c1m = cdm + cam
   END IF
   IF (cdp + cap .LT. zero) THEN
   c1p = zero
   c1pd = 0.0_8
   ELSE
   c1pd = cdpd + capd
   c1p = cdp + cap
   END IF
   c10d = c1md + c1pd
   c10 = c1m + c1p
   ! Update the residual for this cell and store the possible
   ! coefficients for the matrix in b1, c1 and d1.
   dwd(i, j, k, idvt) = dwd(i, j, k, idvt) + c1md*w(i, j-1, k, itu1&
   &         ) + c1m*wd(i, j-1, k, itu1) - c10d*w(i, j, k, itu1) - c10*wd(i&
   &         , j, k, itu1) + c1pd*w(i, j+1, k, itu1) + c1p*wd(i, j+1, k, &
   &         itu1)
   dw(i, j, k, idvt) = dw(i, j, k, idvt) + c1m*w(i, j-1, k, itu1) -&
   &         c10*w(i, j, k, itu1) + c1p*w(i, j+1, k, itu1)
   b1 = -c1m
   c1 = c10
   d1 = -c1p
   ! Update the central jacobian. For nonboundary cells this
   ! is simply c1. For boundary cells this is slightly more
   ! complicated, because the boundary conditions are treated
   ! implicitly and the off-diagonal terms b1 and d1 must be
   ! taken into account.
   ! The boundary conditions are only treated implicitly if
   ! the diagonal dominance of the matrix is increased.
   IF (j .EQ. 2) THEN
   IF (bmtj1(i, k, itu1, itu1) .LT. zero) THEN
   max3 = zero
   ELSE
   max3 = bmtj1(i, k, itu1, itu1)
   END IF
   qq(i, j, k) = qq(i, j, k) + c1 - b1*max3
   ELSE IF (j .EQ. jl) THEN
   IF (bmtj2(i, k, itu1, itu1) .LT. zero) THEN
   max4 = zero
   ELSE
   max4 = bmtj2(i, k, itu1, itu1)
   END IF
   qq(i, j, k) = qq(i, j, k) + c1 - d1*max4
   ELSE
   qq(i, j, k) = qq(i, j, k) + c1
   END IF
   END DO
   END DO
   END DO
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Viscous terms in i-direction.                                  *
   !      *                                                                *
   !      ******************************************************************
   !
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   ! Compute the metrics in xi-direction, i.e. along the
   ! line i = constant.
   volid = -(one*vold(i, j, k)/vol(i, j, k)**2)
   voli = one/vol(i, j, k)
   volmid = -(two*(vold(i, j, k)+vold(i-1, j, k))/(vol(i, j, k)+vol&
   &         (i-1, j, k))**2)
   volmi = two/(vol(i, j, k)+vol(i-1, j, k))
   volpid = -(two*(vold(i, j, k)+vold(i+1, j, k))/(vol(i, j, k)+vol&
   &         (i+1, j, k))**2)
   volpi = two/(vol(i, j, k)+vol(i+1, j, k))
   xmd = sid(i-1, j, k, 1)*volmi + si(i-1, j, k, 1)*volmid
   xm = si(i-1, j, k, 1)*volmi
   ymd = sid(i-1, j, k, 2)*volmi + si(i-1, j, k, 2)*volmid
   ym = si(i-1, j, k, 2)*volmi
   zmd = sid(i-1, j, k, 3)*volmi + si(i-1, j, k, 3)*volmid
   zm = si(i-1, j, k, 3)*volmi
   xpd = sid(i, j, k, 1)*volpi + si(i, j, k, 1)*volpid
   xp = si(i, j, k, 1)*volpi
   ypd = sid(i, j, k, 2)*volpi + si(i, j, k, 2)*volpid
   yp = si(i, j, k, 2)*volpi
   zpd = sid(i, j, k, 3)*volpi + si(i, j, k, 3)*volpid
   zp = si(i, j, k, 3)*volpi
   xad = half*((sid(i, j, k, 1)+sid(i-1, j, k, 1))*voli+(si(i, j, k&
   &         , 1)+si(i-1, j, k, 1))*volid)
   xa = half*(si(i, j, k, 1)+si(i-1, j, k, 1))*voli
   yad = half*((sid(i, j, k, 2)+sid(i-1, j, k, 2))*voli+(si(i, j, k&
   &         , 2)+si(i-1, j, k, 2))*volid)
   ya = half*(si(i, j, k, 2)+si(i-1, j, k, 2))*voli
   zad = half*((sid(i, j, k, 3)+sid(i-1, j, k, 3))*voli+(si(i, j, k&
   &         , 3)+si(i-1, j, k, 3))*volid)
   za = half*(si(i, j, k, 3)+si(i-1, j, k, 3))*voli
   ttmd = xmd*xa + xm*xad + ymd*ya + ym*yad + zmd*za + zm*zad
   ttm = xm*xa + ym*ya + zm*za
   ttpd = xpd*xa + xp*xad + ypd*ya + yp*yad + zpd*za + zp*zad
   ttp = xp*xa + yp*ya + zp*za
   ! Computation of the viscous terms in xi-direction; note
   ! that cross-derivatives are neglected, i.e. the mesh is
   ! assumed to be orthogonal.
   ! Furthermore, the grad(nu)**2 has been rewritten as
   ! div(nu grad(nu)) - nu div(grad nu) to enhance stability.
   ! The second derivative in xi-direction is constructed as
   ! the central difference of the first order derivatives, i.e.
   ! d^2/dxi^2 = d/dxi (d/dxi i+1/2 - d/dxi i-1/2).
   ! In this way the metric can be taken into account.
   ! Compute the diffusion coefficients multiplying the nodes
   ! i+1, i and i-1 in the second derivative. Make sure that
   ! these coefficients are nonnegative.
   cnudd = -(rsacb2*cb3inv*wd(i, j, k, itu1))
   cnud = -(rsacb2*w(i, j, k, itu1)*cb3inv)
   camd = ttmd*cnud + ttm*cnudd
   cam = ttm*cnud
   capd = ttpd*cnud + ttp*cnudd
   cap = ttp*cnud
   nutmd = half*(wd(i-1, j, k, itu1)+wd(i, j, k, itu1))
   nutm = half*(w(i-1, j, k, itu1)+w(i, j, k, itu1))
   nutpd = half*(wd(i+1, j, k, itu1)+wd(i, j, k, itu1))
   nutp = half*(w(i+1, j, k, itu1)+w(i, j, k, itu1))
   nud = (rlvd(i, j, k)*w(i, j, k, irho)-rlv(i, j, k)*wd(i, j, k, &
   &         irho))/w(i, j, k, irho)**2
   nu = rlv(i, j, k)/w(i, j, k, irho)
   numd = half*((rlvd(i-1, j, k)*w(i-1, j, k, irho)-rlv(i-1, j, k)*&
   &         wd(i-1, j, k, irho))/w(i-1, j, k, irho)**2+nud)
   num = half*(rlv(i-1, j, k)/w(i-1, j, k, irho)+nu)
   nupd = half*((rlvd(i+1, j, k)*w(i+1, j, k, irho)-rlv(i+1, j, k)*&
   &         wd(i+1, j, k, irho))/w(i+1, j, k, irho)**2+nud)
   nup = half*(rlv(i+1, j, k)/w(i+1, j, k, irho)+nu)
   cdmd = cb3inv*((numd+(one+rsacb2)*nutmd)*ttm+(num+(one+rsacb2)*&
   &         nutm)*ttmd)
   cdm = (num+(one+rsacb2)*nutm)*ttm*cb3inv
   cdpd = cb3inv*((nupd+(one+rsacb2)*nutpd)*ttp+(nup+(one+rsacb2)*&
   &         nutp)*ttpd)
   cdp = (nup+(one+rsacb2)*nutp)*ttp*cb3inv
   IF (cdm + cam .LT. zero) THEN
   c1m = zero
   c1md = 0.0_8
   ELSE
   c1md = cdmd + camd
   c1m = cdm + cam
   END IF
   IF (cdp + cap .LT. zero) THEN
   c1p = zero
   c1pd = 0.0_8
   ELSE
   c1pd = cdpd + capd
   c1p = cdp + cap
   END IF
   c10d = c1md + c1pd
   c10 = c1m + c1p
   ! Update the residual for this cell and store the possible
   ! coefficients for the matrix in b1, c1 and d1.
   dwd(i, j, k, idvt) = dwd(i, j, k, idvt) + c1md*w(i-1, j, k, itu1&
   &         ) + c1m*wd(i-1, j, k, itu1) - c10d*w(i, j, k, itu1) - c10*wd(i&
   &         , j, k, itu1) + c1pd*w(i+1, j, k, itu1) + c1p*wd(i+1, j, k, &
   &         itu1)
   dw(i, j, k, idvt) = dw(i, j, k, idvt) + c1m*w(i-1, j, k, itu1) -&
   &         c10*w(i, j, k, itu1) + c1p*w(i+1, j, k, itu1)
   b1 = -c1m
   c1 = c10
   d1 = -c1p
   ! Update the central jacobian. For nonboundary cells this
   ! is simply c1. For boundary cells this is slightly more
   ! complicated, because the boundary conditions are treated
   ! implicitly and the off-diagonal terms b1 and d1 must be
   ! taken into account.
   ! The boundary conditions are only treated implicitly if
   ! the diagonal dominance of the matrix is increased.
   IF (i .EQ. 2) THEN
   IF (bmti1(j, k, itu1, itu1) .LT. zero) THEN
   max5 = zero
   ELSE
   max5 = bmti1(j, k, itu1, itu1)
   END IF
   qq(i, j, k) = qq(i, j, k) + c1 - b1*max5
   ELSE IF (i .EQ. il) THEN
   IF (bmti2(j, k, itu1, itu1) .LT. zero) THEN
   max6 = zero
   ELSE
   max6 = bmti2(j, k, itu1, itu1)
   END IF
   qq(i, j, k) = qq(i, j, k) + c1 - d1*max6
   ELSE
   qq(i, j, k) = qq(i, j, k) + c1
   END IF
   END DO
   END DO
   END DO
   ! Multiply the residual by the volume and store this in dw; this
   ! is done for monitoring reasons only. The multiplication with the
   ! volume is present to be consistent with the flow residuals; also
   ! the negative value is taken, again to be consistent with the
   ! flow equations. Also multiply by iblank so that no updates occur
   ! in holes or the overset boundary.
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   rblank = REAL(iblank(i, j, k), realtype)
   dwd(i, j, k, itu1) = -(rblank*(vold(i, j, k)*dw(i, j, k, idvt)+&
   &         vol(i, j, k)*dwd(i, j, k, idvt)))
   dw(i, j, k, itu1) = -(vol(i, j, k)*dw(i, j, k, idvt)*rblank)
   END DO
   END DO
   END DO
   ! Initialize the wall function flags to .false.
   flagi2 = .false.
   flagil = .false.
   flagj2 = .false.
   flagjl = .false.
   flagk2 = .false.
   flagkl = .false.
   ! Modify the rhs of the 1st internal cell, if wall functions
   ! are used; their value is determined by the table.
   ! Return if only the residual must be computed.
   IF (resonly) RETURN
   END SUBROUTINE SASOLVE_D

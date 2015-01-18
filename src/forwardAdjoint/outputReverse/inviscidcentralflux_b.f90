   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of inviscidcentralflux in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: *p *dw *w *vol *si *sj *sk
   !   with respect to varying inputs: *p *dw *w *vol *si *sj *sk
   !                timeref
   !   Plus diff mem management of: p:in dw:in w:in vol:in si:in sj:in
   !                sk:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          inviscidCentralFlux.f90                         *
   !      * Author:        Edwin van der Weide                             *
   !      * Starting date: 03-24-2003                                      *
   !      * Last modified: 10-29-2007                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE INVISCIDCENTRALFLUX_B()
   !
   !      ******************************************************************
   !      *                                                                *
   !      * inviscidCentralFlux computes the Euler fluxes using a central  *
   !      * discretization for a given block. Therefore it is assumed that *
   !      * the pointers in block pointer already point to the correct     *
   !      * block on the correct multigrid level.                          *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BLOCKPOINTERS
   USE CGNSGRID
   USE CONSTANTS
   USE FLOWVARREFSTATE
   USE INPUTPHYSICS
   IMPLICIT NONE
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: i, j, k, ind
   INTEGER(kind=inttype) :: istart, iend, isize, ii
   INTEGER(kind=inttype) :: jstart, jend, jsize
   INTEGER(kind=inttype) :: kstart, kend, ksize
   REAL(kind=realtype) :: qsp, qsm, rqsp, rqsm, porvel, porflux
   REAL(kind=realtype) :: qspd, qsmd, rqspd, rqsmd
   REAL(kind=realtype) :: pa, fs, sface, vnp, vnm
   REAL(kind=realtype) :: pad, fsd, vnpd, vnmd
   REAL(kind=realtype) :: wwx, wwy, wwz, rvol
   REAL(kind=realtype) :: wwxd, wwyd, wwzd, rvold
   INTRINSIC MOD
   INTEGER :: branch
   INTEGER :: ad_from
   INTEGER :: ad_to
   INTEGER :: ad_from0
   INTEGER :: ad_to0
   INTEGER :: ad_from1
   INTEGER :: ad_to1
   INTEGER :: ad_from2
   INTEGER :: ad_to2
   INTEGER :: ad_from3
   INTEGER :: ad_to3
   INTEGER :: ad_from4
   INTEGER :: ad_to4
   INTEGER :: ad_from5
   INTEGER :: ad_to5
   INTEGER :: ad_from6
   INTEGER :: ad_to6
   INTEGER :: ad_from7
   INTEGER :: ad_to7
   REAL(kind=realtype) :: temp3
   REAL(kind=realtype) :: temp2
   REAL(kind=realtype) :: temp1
   REAL(kind=realtype) :: temp0
   REAL(kind=realtype) :: tempd
   REAL(kind=realtype) :: tempd4
   REAL(kind=realtype) :: tempd3
   REAL(kind=realtype) :: tempd2
   REAL(kind=realtype) :: tempd1
   REAL(kind=realtype) :: tempd0
   REAL(kind=realtype) :: temp
   REAL(kind=realtype) :: temp4
   sface = zero
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Advective fluxes in the i-direction.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   istart = 1
   iend = il
   jstart = 2
   jend = jl
   kstart = 2
   kend = kl
   ad_from1 = kstart
   DO k=ad_from1,kend
   ad_from0 = jstart
   DO j=ad_from0,jend
   ad_from = istart
   DO i=ad_from,iend
   ! Set the dot product of the grid velocity and the
   ! normal in i-direction for a moving face.
   IF (addgridvelocities) sface = sfacei(i, j, k)
   ! Compute the normal velocities of the left and right state.
   CALL PUSHREAL8(vnp)
   vnp = w(i+1, j, k, ivx)*si(i, j, k, 1) + w(i+1, j, k, ivy)*si(i&
   &         , j, k, 2) + w(i+1, j, k, ivz)*si(i, j, k, 3)
   CALL PUSHREAL8(vnm)
   vnm = w(i, j, k, ivx)*si(i, j, k, 1) + w(i, j, k, ivy)*si(i, j, &
   &         k, 2) + w(i, j, k, ivz)*si(i, j, k, 3)
   ! Set the values of the porosities for this face.
   ! porVel defines the porosity w.r.t. velocity;
   ! porFlux defines the porosity w.r.t. the entire flux.
   ! The latter is only zero for a discontinuous block
   ! boundary that must be treated conservatively.
   ! The default value of porFlux is 0.5, such that the
   ! correct central flux is scattered to both cells.
   ! In case of a boundFlux the normal velocity is set
   ! to sFace.
   CALL PUSHREAL8(porvel)
   porvel = one
   CALL PUSHREAL8(porflux)
   porflux = half
   IF (pori(i, j, k) .EQ. noflux) porflux = zero
   IF (pori(i, j, k) .EQ. boundflux) THEN
   porvel = zero
   vnp = sface
   vnm = sface
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   ! Incorporate porFlux in porVel.
   porvel = porvel*porflux
   ! Compute the normal velocities relative to the grid for
   ! the face as well as the mass fluxes.
   CALL PUSHREAL8(qsp)
   qsp = (vnp-sface)*porvel
   CALL PUSHREAL8(qsm)
   qsm = (vnm-sface)*porvel
   ! Compute the sum of the pressure multiplied by porFlux.
   ! For the default value of porFlux, 0.5, this leads to
   ! the average pressure.
   ! Compute the fluxes and scatter them to the cells
   ! i,j,k and i+1,j,k. Store the density flux in the
   ! mass flow of the appropriate sliding mesh interface.
   END DO
   CALL PUSHINTEGER4(i - 1)
   CALL PUSHINTEGER4(ad_from)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from0)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from1)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Advective fluxes in the j-direction.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   istart = 2
   iend = il
   jstart = 1
   jend = jl
   kstart = 2
   kend = kl
   ad_from4 = kstart
   DO k=ad_from4,kend
   ad_from3 = jstart
   DO j=ad_from3,jend
   ad_from2 = istart
   DO i=ad_from2,iend
   ! Set the dot product of the grid velocity and the
   ! normal in j-direction for a moving face.
   IF (addgridvelocities) sface = sfacej(i, j, k)
   ! Compute the normal velocities of the left and right state.
   CALL PUSHREAL8(vnp)
   vnp = w(i, j+1, k, ivx)*sj(i, j, k, 1) + w(i, j+1, k, ivy)*sj(i&
   &         , j, k, 2) + w(i, j+1, k, ivz)*sj(i, j, k, 3)
   CALL PUSHREAL8(vnm)
   vnm = w(i, j, k, ivx)*sj(i, j, k, 1) + w(i, j, k, ivy)*sj(i, j, &
   &         k, 2) + w(i, j, k, ivz)*sj(i, j, k, 3)
   ! Set the values of the porosities for this face.
   ! porVel defines the porosity w.r.t. velocity;
   ! porFlux defines the porosity w.r.t. the entire flux.
   ! The latter is only zero for a discontinuous block
   ! boundary that must be treated conservatively.
   ! The default value of porFlux is 0.5, such that the
   ! correct central flux is scattered to both cells.
   ! In case of a boundFlux the normal velocity is set
   ! to sFace.
   CALL PUSHREAL8(porvel)
   porvel = one
   CALL PUSHREAL8(porflux)
   porflux = half
   IF (porj(i, j, k) .EQ. noflux) porflux = zero
   IF (porj(i, j, k) .EQ. boundflux) THEN
   porvel = zero
   vnp = sface
   vnm = sface
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   ! Incorporate porFlux in porVel.
   porvel = porvel*porflux
   ! Compute the normal velocities for the face as well as the
   ! mass fluxes.
   CALL PUSHREAL8(qsp)
   qsp = (vnp-sface)*porvel
   CALL PUSHREAL8(qsm)
   qsm = (vnm-sface)*porvel
   ! Compute the sum of the pressure multiplied by porFlux.
   ! For the default value of porFlux, 0.5, this leads to
   ! the average pressure.
   ! Compute the fluxes and scatter them to the cells
   ! i,j,k and i,j+1,k. Store the density flux in the
   ! mass flow of the appropriate sliding mesh interface.
   END DO
   CALL PUSHINTEGER4(i - 1)
   CALL PUSHINTEGER4(ad_from2)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from3)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from4)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Advective fluxes in the k-direction.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   istart = 2
   iend = il
   jstart = 2
   jend = jl
   kstart = 1
   kend = kl
   ad_from7 = kstart
   DO k=ad_from7,kend
   ad_from6 = jstart
   DO j=ad_from6,jend
   ad_from5 = istart
   DO i=ad_from5,iend
   ! Set the dot product of the grid velocity and the
   ! normal in k-direction for a moving face.
   IF (addgridvelocities) sface = sfacek(i, j, k)
   ! Compute the normal velocities of the left and right state.
   CALL PUSHREAL8(vnp)
   vnp = w(i, j, k+1, ivx)*sk(i, j, k, 1) + w(i, j, k+1, ivy)*sk(i&
   &         , j, k, 2) + w(i, j, k+1, ivz)*sk(i, j, k, 3)
   CALL PUSHREAL8(vnm)
   vnm = w(i, j, k, ivx)*sk(i, j, k, 1) + w(i, j, k, ivy)*sk(i, j, &
   &         k, 2) + w(i, j, k, ivz)*sk(i, j, k, 3)
   ! Set the values of the porosities for this face.
   ! porVel defines the porosity w.r.t. velocity;
   ! porFlux defines the porosity w.r.t. the entire flux.
   ! The latter is only zero for a discontinuous block
   ! block boundary that must be treated conservatively.
   ! The default value of porFlux is 0.5, such that the
   ! correct central flux is scattered to both cells.
   ! In case of a boundFlux the normal velocity is set
   ! to sFace.
   CALL PUSHREAL8(porvel)
   porvel = one
   CALL PUSHREAL8(porflux)
   porflux = half
   IF (pork(i, j, k) .EQ. noflux) porflux = zero
   IF (pork(i, j, k) .EQ. boundflux) THEN
   porvel = zero
   vnp = sface
   vnm = sface
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   ! Incorporate porFlux in porVel.
   porvel = porvel*porflux
   ! Compute the normal velocities for the face as well as the
   ! mass fluxes.
   CALL PUSHREAL8(qsp)
   qsp = (vnp-sface)*porvel
   CALL PUSHREAL8(qsm)
   qsm = (vnm-sface)*porvel
   ! Compute the sum of the pressure multiplied by porFlux.
   ! For the default value of porFlux, 0.5, this leads to
   ! the average pressure.
   ! Compute the fluxes and scatter them to the cells
   ! i,j,k and i,j,k+1. Store the density flux in the
   ! mass flow of the appropriate sliding mesh interface.
   END DO
   CALL PUSHINTEGER4(i - 1)
   CALL PUSHINTEGER4(ad_from5)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from6)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from7)
   ! Add the rotational source terms for a moving block in a
   ! steady state computation. These source terms account for the
   ! centrifugal acceleration and the coriolis term. However, as
   ! the the equations are solved in the inertial frame and not
   ! in the moving frame, the form is different than what you
   ! normally find in a text book.
   IF (blockismoving .AND. equationmode .EQ. steady) THEN
   ! Compute the three nonDimensional angular velocities.
   wwx = timeref*cgnsdoms(nbkglobal)%rotrate(1)
   wwy = timeref*cgnsdoms(nbkglobal)%rotrate(2)
   wwz = timeref*cgnsdoms(nbkglobal)%rotrate(3)
   ! Loop over the internal cells of this block to compute the
   ! rotational terms for the momentum equations.
   istart = 2
   iend = il
   isize = iend - istart + 1
   jstart = 2
   jend = jl
   jsize = jend - jstart + 1
   kstart = 2
   kend = kl
   ksize = kend - kstart + 1
   wwxd = 0.0_8
   wwyd = 0.0_8
   wwzd = 0.0_8
   DO ii=0,isize*jsize*ksize-1
   i = MOD(ii, isize) + istart
   j = MOD(ii/isize, jsize) + jstart
   k = ii/(isize*jsize) + kstart
   rvol = w(i, j, k, irho)*vol(i, j, k)
   temp4 = w(i, j, k, ivx)
   temp3 = w(i, j, k, ivy)
   tempd2 = rvol*dwd(i, j, k, imz)
   rvold = (wwx*temp3-wwy*temp4)*dwd(i, j, k, imz)
   wd(i, j, k, ivy) = wd(i, j, k, ivy) + wwx*tempd2
   wd(i, j, k, ivx) = wd(i, j, k, ivx) - wwy*tempd2
   temp2 = w(i, j, k, ivz)
   temp1 = w(i, j, k, ivx)
   tempd3 = rvol*dwd(i, j, k, imy)
   wwxd = wwxd + temp3*tempd2 - temp2*tempd3
   rvold = rvold + (wwz*temp1-wwx*temp2)*dwd(i, j, k, imy)
   wd(i, j, k, ivx) = wd(i, j, k, ivx) + wwz*tempd3
   wd(i, j, k, ivz) = wd(i, j, k, ivz) - wwx*tempd3
   temp0 = w(i, j, k, ivy)
   temp = w(i, j, k, ivz)
   tempd4 = rvol*dwd(i, j, k, imx)
   wwyd = wwyd + temp*tempd4 - temp4*tempd2
   wwzd = wwzd + temp1*tempd3 - temp0*tempd4
   rvold = rvold + (wwy*temp-wwz*temp0)*dwd(i, j, k, imx)
   wd(i, j, k, ivz) = wd(i, j, k, ivz) + wwy*tempd4
   wd(i, j, k, ivy) = wd(i, j, k, ivy) - wwz*tempd4
   wd(i, j, k, irho) = wd(i, j, k, irho) + vol(i, j, k)*rvold
   vold(i, j, k) = vold(i, j, k) + w(i, j, k, irho)*rvold
   END DO
   timerefd = cgnsdoms(nbkglobal)%rotrate(2)*wwyd + cgnsdoms(nbkglobal)&
   &     %rotrate(1)*wwxd + cgnsdoms(nbkglobal)%rotrate(3)*wwzd
   ELSE
   timerefd = 0.0_8
   END IF
   CALL POPINTEGER4(ad_from7)
   CALL POPINTEGER4(ad_to7)
   DO k=ad_to7,ad_from7,-1
   CALL POPINTEGER4(ad_from6)
   CALL POPINTEGER4(ad_to6)
   DO j=ad_to6,ad_from6,-1
   CALL POPINTEGER4(ad_from5)
   CALL POPINTEGER4(ad_to5)
   DO i=ad_to5,ad_from5,-1
   fsd = dwd(i, j, k, irhoe) - dwd(i, j, k+1, irhoe)
   tempd1 = porflux*fsd
   qspd = w(i, j, k+1, irhoe)*fsd
   wd(i, j, k+1, irhoe) = wd(i, j, k+1, irhoe) + qsp*fsd
   qsmd = w(i, j, k, irhoe)*fsd
   wd(i, j, k, irhoe) = wd(i, j, k, irhoe) + qsm*fsd
   pd(i, j, k+1) = pd(i, j, k+1) + vnp*tempd1
   pd(i, j, k) = pd(i, j, k) + vnm*tempd1
   fsd = dwd(i, j, k, imz) - dwd(i, j, k+1, imz)
   rqsm = qsm*w(i, j, k, irho)
   rqsp = qsp*w(i, j, k+1, irho)
   pa = porflux*(p(i, j, k+1)+p(i, j, k))
   rqspd = w(i, j, k+1, ivz)*fsd
   wd(i, j, k+1, ivz) = wd(i, j, k+1, ivz) + rqsp*fsd
   rqsmd = w(i, j, k, ivz)*fsd
   wd(i, j, k, ivz) = wd(i, j, k, ivz) + rqsm*fsd
   pad = sk(i, j, k, 3)*fsd
   skd(i, j, k, 3) = skd(i, j, k, 3) + pa*fsd
   fsd = dwd(i, j, k, imy) - dwd(i, j, k+1, imy)
   rqspd = rqspd + w(i, j, k+1, ivy)*fsd
   wd(i, j, k+1, ivy) = wd(i, j, k+1, ivy) + rqsp*fsd
   rqsmd = rqsmd + w(i, j, k, ivy)*fsd
   wd(i, j, k, ivy) = wd(i, j, k, ivy) + rqsm*fsd
   pad = pad + sk(i, j, k, 2)*fsd
   skd(i, j, k, 2) = skd(i, j, k, 2) + pa*fsd
   fsd = dwd(i, j, k, imx) - dwd(i, j, k+1, imx)
   rqspd = rqspd + w(i, j, k+1, ivx)*fsd
   wd(i, j, k+1, ivx) = wd(i, j, k+1, ivx) + rqsp*fsd
   rqsmd = rqsmd + w(i, j, k, ivx)*fsd
   wd(i, j, k, ivx) = wd(i, j, k, ivx) + rqsm*fsd
   pad = pad + sk(i, j, k, 1)*fsd
   skd(i, j, k, 1) = skd(i, j, k, 1) + pa*fsd
   fsd = dwd(i, j, k, irho) - dwd(i, j, k+1, irho)
   rqspd = rqspd + fsd
   rqsmd = rqsmd + fsd
   pd(i, j, k+1) = pd(i, j, k+1) + porflux*pad
   pd(i, j, k) = pd(i, j, k) + porflux*pad
   qsmd = qsmd + w(i, j, k, irho)*rqsmd
   vnmd = porvel*qsmd + p(i, j, k)*tempd1
   wd(i, j, k, irho) = wd(i, j, k, irho) + qsm*rqsmd
   qspd = qspd + w(i, j, k+1, irho)*rqspd
   vnpd = porvel*qspd + p(i, j, k+1)*tempd1
   wd(i, j, k+1, irho) = wd(i, j, k+1, irho) + qsp*rqspd
   CALL POPREAL8(qsm)
   CALL POPREAL8(qsp)
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   vnmd = 0.0_8
   vnpd = 0.0_8
   END IF
   CALL POPREAL8(porflux)
   CALL POPREAL8(porvel)
   CALL POPREAL8(vnm)
   wd(i, j, k, ivx) = wd(i, j, k, ivx) + sk(i, j, k, 1)*vnmd
   skd(i, j, k, 1) = skd(i, j, k, 1) + w(i, j, k, ivx)*vnmd
   wd(i, j, k, ivy) = wd(i, j, k, ivy) + sk(i, j, k, 2)*vnmd
   skd(i, j, k, 2) = skd(i, j, k, 2) + w(i, j, k, ivy)*vnmd
   wd(i, j, k, ivz) = wd(i, j, k, ivz) + sk(i, j, k, 3)*vnmd
   skd(i, j, k, 3) = skd(i, j, k, 3) + w(i, j, k, ivz)*vnmd
   CALL POPREAL8(vnp)
   wd(i, j, k+1, ivx) = wd(i, j, k+1, ivx) + sk(i, j, k, 1)*vnpd
   skd(i, j, k, 1) = skd(i, j, k, 1) + w(i, j, k+1, ivx)*vnpd
   wd(i, j, k+1, ivy) = wd(i, j, k+1, ivy) + sk(i, j, k, 2)*vnpd
   skd(i, j, k, 2) = skd(i, j, k, 2) + w(i, j, k+1, ivy)*vnpd
   wd(i, j, k+1, ivz) = wd(i, j, k+1, ivz) + sk(i, j, k, 3)*vnpd
   skd(i, j, k, 3) = skd(i, j, k, 3) + w(i, j, k+1, ivz)*vnpd
   END DO
   END DO
   END DO
   CALL POPINTEGER4(ad_from4)
   CALL POPINTEGER4(ad_to4)
   DO k=ad_to4,ad_from4,-1
   CALL POPINTEGER4(ad_from3)
   CALL POPINTEGER4(ad_to3)
   DO j=ad_to3,ad_from3,-1
   CALL POPINTEGER4(ad_from2)
   CALL POPINTEGER4(ad_to2)
   DO i=ad_to2,ad_from2,-1
   fsd = dwd(i, j, k, irhoe) - dwd(i, j+1, k, irhoe)
   tempd0 = porflux*fsd
   qspd = w(i, j+1, k, irhoe)*fsd
   wd(i, j+1, k, irhoe) = wd(i, j+1, k, irhoe) + qsp*fsd
   qsmd = w(i, j, k, irhoe)*fsd
   wd(i, j, k, irhoe) = wd(i, j, k, irhoe) + qsm*fsd
   pd(i, j+1, k) = pd(i, j+1, k) + vnp*tempd0
   pd(i, j, k) = pd(i, j, k) + vnm*tempd0
   fsd = dwd(i, j, k, imz) - dwd(i, j+1, k, imz)
   rqsm = qsm*w(i, j, k, irho)
   rqsp = qsp*w(i, j+1, k, irho)
   pa = porflux*(p(i, j+1, k)+p(i, j, k))
   rqspd = w(i, j+1, k, ivz)*fsd
   wd(i, j+1, k, ivz) = wd(i, j+1, k, ivz) + rqsp*fsd
   rqsmd = w(i, j, k, ivz)*fsd
   wd(i, j, k, ivz) = wd(i, j, k, ivz) + rqsm*fsd
   pad = sj(i, j, k, 3)*fsd
   sjd(i, j, k, 3) = sjd(i, j, k, 3) + pa*fsd
   fsd = dwd(i, j, k, imy) - dwd(i, j+1, k, imy)
   rqspd = rqspd + w(i, j+1, k, ivy)*fsd
   wd(i, j+1, k, ivy) = wd(i, j+1, k, ivy) + rqsp*fsd
   rqsmd = rqsmd + w(i, j, k, ivy)*fsd
   wd(i, j, k, ivy) = wd(i, j, k, ivy) + rqsm*fsd
   pad = pad + sj(i, j, k, 2)*fsd
   sjd(i, j, k, 2) = sjd(i, j, k, 2) + pa*fsd
   fsd = dwd(i, j, k, imx) - dwd(i, j+1, k, imx)
   rqspd = rqspd + w(i, j+1, k, ivx)*fsd
   wd(i, j+1, k, ivx) = wd(i, j+1, k, ivx) + rqsp*fsd
   rqsmd = rqsmd + w(i, j, k, ivx)*fsd
   wd(i, j, k, ivx) = wd(i, j, k, ivx) + rqsm*fsd
   pad = pad + sj(i, j, k, 1)*fsd
   sjd(i, j, k, 1) = sjd(i, j, k, 1) + pa*fsd
   fsd = dwd(i, j, k, irho) - dwd(i, j+1, k, irho)
   rqspd = rqspd + fsd
   rqsmd = rqsmd + fsd
   pd(i, j+1, k) = pd(i, j+1, k) + porflux*pad
   pd(i, j, k) = pd(i, j, k) + porflux*pad
   qsmd = qsmd + w(i, j, k, irho)*rqsmd
   vnmd = porvel*qsmd + p(i, j, k)*tempd0
   wd(i, j, k, irho) = wd(i, j, k, irho) + qsm*rqsmd
   qspd = qspd + w(i, j+1, k, irho)*rqspd
   vnpd = porvel*qspd + p(i, j+1, k)*tempd0
   wd(i, j+1, k, irho) = wd(i, j+1, k, irho) + qsp*rqspd
   CALL POPREAL8(qsm)
   CALL POPREAL8(qsp)
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   vnmd = 0.0_8
   vnpd = 0.0_8
   END IF
   CALL POPREAL8(porflux)
   CALL POPREAL8(porvel)
   CALL POPREAL8(vnm)
   wd(i, j, k, ivx) = wd(i, j, k, ivx) + sj(i, j, k, 1)*vnmd
   sjd(i, j, k, 1) = sjd(i, j, k, 1) + w(i, j, k, ivx)*vnmd
   wd(i, j, k, ivy) = wd(i, j, k, ivy) + sj(i, j, k, 2)*vnmd
   sjd(i, j, k, 2) = sjd(i, j, k, 2) + w(i, j, k, ivy)*vnmd
   wd(i, j, k, ivz) = wd(i, j, k, ivz) + sj(i, j, k, 3)*vnmd
   sjd(i, j, k, 3) = sjd(i, j, k, 3) + w(i, j, k, ivz)*vnmd
   CALL POPREAL8(vnp)
   wd(i, j+1, k, ivx) = wd(i, j+1, k, ivx) + sj(i, j, k, 1)*vnpd
   sjd(i, j, k, 1) = sjd(i, j, k, 1) + w(i, j+1, k, ivx)*vnpd
   wd(i, j+1, k, ivy) = wd(i, j+1, k, ivy) + sj(i, j, k, 2)*vnpd
   sjd(i, j, k, 2) = sjd(i, j, k, 2) + w(i, j+1, k, ivy)*vnpd
   wd(i, j+1, k, ivz) = wd(i, j+1, k, ivz) + sj(i, j, k, 3)*vnpd
   sjd(i, j, k, 3) = sjd(i, j, k, 3) + w(i, j+1, k, ivz)*vnpd
   END DO
   END DO
   END DO
   CALL POPINTEGER4(ad_from1)
   CALL POPINTEGER4(ad_to1)
   DO k=ad_to1,ad_from1,-1
   CALL POPINTEGER4(ad_from0)
   CALL POPINTEGER4(ad_to0)
   DO j=ad_to0,ad_from0,-1
   CALL POPINTEGER4(ad_from)
   CALL POPINTEGER4(ad_to)
   DO i=ad_to,ad_from,-1
   fsd = dwd(i, j, k, irhoe) - dwd(i+1, j, k, irhoe)
   tempd = porflux*fsd
   qspd = w(i+1, j, k, irhoe)*fsd
   wd(i+1, j, k, irhoe) = wd(i+1, j, k, irhoe) + qsp*fsd
   qsmd = w(i, j, k, irhoe)*fsd
   wd(i, j, k, irhoe) = wd(i, j, k, irhoe) + qsm*fsd
   pd(i+1, j, k) = pd(i+1, j, k) + vnp*tempd
   pd(i, j, k) = pd(i, j, k) + vnm*tempd
   fsd = dwd(i, j, k, imz) - dwd(i+1, j, k, imz)
   rqsm = qsm*w(i, j, k, irho)
   rqsp = qsp*w(i+1, j, k, irho)
   pa = porflux*(p(i+1, j, k)+p(i, j, k))
   rqspd = w(i+1, j, k, ivz)*fsd
   wd(i+1, j, k, ivz) = wd(i+1, j, k, ivz) + rqsp*fsd
   rqsmd = w(i, j, k, ivz)*fsd
   wd(i, j, k, ivz) = wd(i, j, k, ivz) + rqsm*fsd
   pad = si(i, j, k, 3)*fsd
   sid(i, j, k, 3) = sid(i, j, k, 3) + pa*fsd
   fsd = dwd(i, j, k, imy) - dwd(i+1, j, k, imy)
   rqspd = rqspd + w(i+1, j, k, ivy)*fsd
   wd(i+1, j, k, ivy) = wd(i+1, j, k, ivy) + rqsp*fsd
   rqsmd = rqsmd + w(i, j, k, ivy)*fsd
   wd(i, j, k, ivy) = wd(i, j, k, ivy) + rqsm*fsd
   pad = pad + si(i, j, k, 2)*fsd
   sid(i, j, k, 2) = sid(i, j, k, 2) + pa*fsd
   fsd = dwd(i, j, k, imx) - dwd(i+1, j, k, imx)
   rqspd = rqspd + w(i+1, j, k, ivx)*fsd
   wd(i+1, j, k, ivx) = wd(i+1, j, k, ivx) + rqsp*fsd
   rqsmd = rqsmd + w(i, j, k, ivx)*fsd
   wd(i, j, k, ivx) = wd(i, j, k, ivx) + rqsm*fsd
   pad = pad + si(i, j, k, 1)*fsd
   sid(i, j, k, 1) = sid(i, j, k, 1) + pa*fsd
   fsd = dwd(i, j, k, irho) - dwd(i+1, j, k, irho)
   rqspd = rqspd + fsd
   rqsmd = rqsmd + fsd
   pd(i+1, j, k) = pd(i+1, j, k) + porflux*pad
   pd(i, j, k) = pd(i, j, k) + porflux*pad
   qsmd = qsmd + w(i, j, k, irho)*rqsmd
   vnmd = porvel*qsmd + p(i, j, k)*tempd
   wd(i, j, k, irho) = wd(i, j, k, irho) + qsm*rqsmd
   qspd = qspd + w(i+1, j, k, irho)*rqspd
   vnpd = porvel*qspd + p(i+1, j, k)*tempd
   wd(i+1, j, k, irho) = wd(i+1, j, k, irho) + qsp*rqspd
   CALL POPREAL8(qsm)
   CALL POPREAL8(qsp)
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   vnmd = 0.0_8
   vnpd = 0.0_8
   END IF
   CALL POPREAL8(porflux)
   CALL POPREAL8(porvel)
   CALL POPREAL8(vnm)
   wd(i, j, k, ivx) = wd(i, j, k, ivx) + si(i, j, k, 1)*vnmd
   sid(i, j, k, 1) = sid(i, j, k, 1) + w(i, j, k, ivx)*vnmd
   wd(i, j, k, ivy) = wd(i, j, k, ivy) + si(i, j, k, 2)*vnmd
   sid(i, j, k, 2) = sid(i, j, k, 2) + w(i, j, k, ivy)*vnmd
   wd(i, j, k, ivz) = wd(i, j, k, ivz) + si(i, j, k, 3)*vnmd
   sid(i, j, k, 3) = sid(i, j, k, 3) + w(i, j, k, ivz)*vnmd
   CALL POPREAL8(vnp)
   wd(i+1, j, k, ivx) = wd(i+1, j, k, ivx) + si(i, j, k, 1)*vnpd
   sid(i, j, k, 1) = sid(i, j, k, 1) + w(i+1, j, k, ivx)*vnpd
   wd(i+1, j, k, ivy) = wd(i+1, j, k, ivy) + si(i, j, k, 2)*vnpd
   sid(i, j, k, 2) = sid(i, j, k, 2) + w(i+1, j, k, ivy)*vnpd
   wd(i+1, j, k, ivz) = wd(i+1, j, k, ivz) + si(i, j, k, 3)*vnpd
   sid(i, j, k, 3) = sid(i, j, k, 3) + w(i+1, j, k, ivz)*vnpd
   END DO
   END DO
   END DO
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Initialize sFace to zero. This value will be used if the
   ! block is not moving.
   40 FORMAT(1x,i4,i4,i4,e20.6)
   END SUBROUTINE INVISCIDCENTRALFLUX_B

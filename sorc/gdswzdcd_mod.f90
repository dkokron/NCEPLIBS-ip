 MODULE GDSWZDCD_MOD
!$$$  MODULE DOCUMENTATION BLOCK
!
! $Revision$
!
! MODULE:  GDSWZDCD_MOD  GDS WIZARD MODULE FOR ROTATED EQUIDISTANT
!                        CYLINDRICAL GRIDS (NON "E" STAGGER).
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: - CONVERT FROM EARTH TO GRID COORDINATES OR VICE VERSA.
!           - COMPUTE VECTOR ROTATION SINES AND COSINES.
!           - COMPUTE MAP JACOBIANS.
!           - COMPUTE GRID BOX AREA.
!
! PROGRAM HISTORY LOG:
!   2015-01-21  GAYNO   INITIAL VERSION FROM A MERGER OF
!                       ROUTINES GDSWIZCD AND GDSWZDCD.
!
! USAGE:  "USE GDSWZDCD_MOD"  THEN CALL THE PUBLIC DRIVER
!         ROUTINE "GDSWZDCD".
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
 IMPLICIT NONE

 PRIVATE

 PUBLIC                                 :: GDSWZDCD

 INTEGER,                 PARAMETER     :: KD=SELECTED_REAL_KIND(15,45)

 REAL(KIND=KD),           PARAMETER     :: RERTH=6.3712E6_KD
 REAL(KIND=KD),           PARAMETER     :: PI=3.14159265358979_KD
 REAL(KIND=KD),           PARAMETER     :: DPR=180._KD/PI

 INTEGER                                :: IROT

 REAL(KIND=KD)                          :: CLAT, CLON
 REAL(KIND=KD)                          :: CLAT0, CLATR, DLATS, DLONS
 REAL(KIND=KD)                          :: RLON0, SLAT, SLAT0, SLATR

 CONTAINS

 SUBROUTINE GDSWZDCD(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET, &
                     CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZDCD   GDS WIZARD FOR ROTATED EQUIDISTANT CYLINDRICAL
!   PRGMMR: GAYNO       ORG: W/NMC23       DATE: 2007-NOV-15
!
! ABSTRACT: THIS SUBPROGRAM DECODES THE GRIB GRID DESCRIPTION SECTION
!           (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63)
!           AND RETURNS ONE OF THE FOLLOWING:
!             (IOPT=+1) EARTH COORDINATES OF SELECTED GRID COORDINATES
!             (IOPT=-1) GRID COORDINATES OF SELECTED EARTH COORDINATES
!           FOR NON-"E" STAGGERED ROTATED EQUIDISTANT CYLINDRICAL PROJECTIONS.
!           (MASS OR VELOCITY POINTS.)
!           IF THE SELECTED COORDINATES ARE MORE THAN ONE GRIDPOINT
!           BEYOND THE THE EDGES OF THE GRID DOMAIN, THEN THE RELEVANT
!           OUTPUT ELEMENTS ARE SET TO FILL VALUES.
!           THE ACTUAL NUMBER OF VALID POINTS COMPUTED IS RETURNED TOO.
!           OPTIONALLY, THE VECTOR ROTATIONS, THE MAP JACOBIANS AND
!           THE GRID BOX AREAS MAY BE RETURNED AS WELL.  TO COMPUTE
!           THE VECTOR ROTATIONS, THE OPTIONAL ARGUMENTS 'SROT' AND 'CROT'
!           MUST BE PRESENT.  TO COMPUTE THE MAP JACOBIANS, THE
!           OPTIONAL ARGUMENTS 'XLON', 'XLAT', 'YLON', 'YLAT' MUST BE PRESENT.
!           TO COMPUTE THE GRID BOX AREAS, THE OPTIONAL ARGUMENT
!           'AREA' MUST BE PRESENT.
!
! PROGRAM HISTORY LOG:
! 2010-JAN-15  GAYNO     BASED ON ROUTINES GDSWZDCB AND GDSWZDCA
! 2015-JAN-21  GAYNO     MERGER OF GDSWIZCD AND GDSWZDCD.  MAKE
!                        CROT,SORT,XLON,XLAT,YLON,YLAT AND AREA
!                        OPTIONAL ARGUMENTS.  MAKE PART OF A MODULE.
!                        MOVE VECTOR ROTATION, MAP JACOBIAN AND GRID
!                        BOX AREA COMPUTATIONS TO SEPARATE SUBROUTINES.
!
! USAGE:    CALL GDSWZDCD(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET,
!     &                   CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
!
!   INPUT ARGUMENT LIST:
!     KGDS     - INTEGER (200) GDS PARAMETERS AS DECODED BY W3FI63
!     IOPT     - INTEGER OPTION FLAG
!                (+1 TO COMPUTE EARTH COORDS OF SELECTED GRID COORDS)
!                (-1 TO COMPUTE GRID COORDS OF SELECTED EARTH COORDS)
!     NPTS     - INTEGER MAXIMUM NUMBER OF COORDINATES
!     FILL     - REAL FILL VALUE TO SET INVALID OUTPUT DATA
!                (MUST BE IMPOSSIBLE VALUE; SUGGESTED VALUE: -9999.)
!     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT>0
!     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT>0
!     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT<0
!                (ACCEPTABLE RANGE: -360. TO 360.)
!     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT<0
!                (ACCEPTABLE RANGE: -90. TO 90.)
!
!   OUTPUT ARGUMENT LIST:
!     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT<0
!     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT<0
!     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT>0
!     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT>0
!     NRET     - INTEGER NUMBER OF VALID POINTS COMPUTED
!     CROT     - REAL, OPTIONAL (NPTS) CLOCKWISE VECTOR ROTATION COSINES
!     SROT     - REAL, OPTIONAL (NPTS) CLOCKWISE VECTOR ROTATION SINES
!                (UGRID=CROT*UEARTH-SROT*VEARTH;
!                 VGRID=SROT*UEARTH+CROT*VEARTH)
!     XLON     - REAL, OPTIONAL (NPTS) DX/DLON IN 1/DEGREES
!     XLAT     - REAL, OPTIONAL (NPTS) DX/DLAT IN 1/DEGREES
!     YLON     - REAL, OPTIONAL (NPTS) DY/DLON IN 1/DEGREES
!     YLAT     - REAL, OPTIONAL (NPTS) DY/DLAT IN 1/DEGREES
!     AREA     - REAL, OPTIONAL (NPTS) AREA WEIGHTS IN M**2
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,                 INTENT(IN   ) :: IOPT,KGDS(200),NPTS
 INTEGER,                 INTENT(  OUT) :: NRET
!
 REAL,                    INTENT(IN   ) :: FILL
 REAL,                    INTENT(INOUT) :: RLON(NPTS),RLAT(NPTS)
 REAL,                    INTENT(INOUT) :: XPTS(NPTS),YPTS(NPTS)
 REAL,  OPTIONAL,         INTENT(  OUT) :: CROT(NPTS),SROT(NPTS)
 REAL,  OPTIONAL,         INTENT(  OUT) :: XLON(NPTS),XLAT(NPTS)
 REAL,  OPTIONAL,         INTENT(  OUT) :: YLON(NPTS),YLAT(NPTS),AREA(NPTS)
!
 INTEGER                                :: IM,JM,ISCAN,JSCAN,N
!
 LOGICAL                                :: LROT, LMAP, LAREA
!
 REAL(KIND=KD)                          :: HI,HJ,HS,HS2
 REAL(KIND=KD)                          :: RLAT1,RLON1,RLAT0,RLAT2,RLON2
 REAL(KIND=KD)                          :: SLAT1,CLAT1
 REAL(KIND=KD)                          :: SLAT2,CLAT2,CLON2
 REAL(KIND=KD)                          :: CLON1,CLONR
 REAL(KIND=KD)                          :: RLATR,RLONR
 REAL(KIND=KD)                          :: WBD,SBD,NBD,EBD
 REAL                                   :: XMIN,XMAX,YMIN,YMAX
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 IF(PRESENT(CROT)) CROT=FILL
 IF(PRESENT(SROT)) SROT=FILL
 IF(PRESENT(XLON)) XLON=FILL
 IF(PRESENT(XLAT)) XLAT=FILL
 IF(PRESENT(YLON)) YLON=FILL
 IF(PRESENT(YLAT)) YLAT=FILL
 IF(PRESENT(AREA)) AREA=FILL
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 IF(KGDS(1).EQ.205) THEN
   RLAT1=KGDS(4)*1.E-3_KD
   RLON1=KGDS(5)*1.E-3_KD
   RLAT0=KGDS(7)*1.E-3_KD
   RLON0=KGDS(8)*1.E-3_KD
   RLAT2=KGDS(12)*1.E-3_KD
   RLON2=KGDS(13)*1.E-3_KD
   IROT=MOD(KGDS(6)/8,2)
   IM=KGDS(2)
   JM=KGDS(3)
   ISCAN=MOD(KGDS(11)/128,2)
   JSCAN=MOD(KGDS(11)/64,2)
   HI=(-1.)**ISCAN
   HJ=(-1.)**(1-JSCAN)
   SLAT1=SIN(RLAT1/DPR)
   CLAT1=COS(RLAT1/DPR)
   SLAT0=SIN(RLAT0/DPR)
   CLAT0=COS(RLAT0/DPR)
   HS=SIGN(1._KD,MOD(RLON1-RLON0+180+3600,360._KD)-180)
   CLON1=COS((RLON1-RLON0)/DPR)
   SLATR=CLAT0*SLAT1-SLAT0*CLAT1*CLON1
   CLATR=SQRT(1-SLATR**2)
   CLONR=(CLAT0*CLAT1*CLON1+SLAT0*SLAT1)/CLATR
   RLATR=DPR*ASIN(SLATR)
   RLONR=HS*DPR*ACOS(CLONR)
   WBD=RLONR
   SBD=RLATR
   SLAT2=SIN(RLAT2/DPR)
   CLAT2=COS(RLAT2/DPR)
   HS2=SIGN(1._KD,MOD(RLON2-RLON0+180+3600,360._KD)-180)
   CLON2=COS((RLON2-RLON0)/DPR)
   SLATR=CLAT0*SLAT2-SLAT0*CLAT2*CLON2
   CLATR=SQRT(1-SLATR**2)
   CLONR=(CLAT0*CLAT2*CLON2+SLAT0*SLAT2)/CLATR
   NBD=DPR*ASIN(SLATR)
   EBD=HS2*DPR*ACOS(CLONR)
   DLATS=(NBD-SBD)/FLOAT(JM-1)
   DLONS=(EBD-WBD)/FLOAT(IM-1)
   XMIN=0
   XMAX=IM+1
   YMIN=0
   YMAX=JM+1
   NRET=0
   IF(PRESENT(CROT).AND.PRESENT(SROT))THEN
     LROT=.TRUE.
   ELSE
     LROT=.FALSE.
   ENDIF
   IF(PRESENT(XLON).AND.PRESENT(XLAT).AND.PRESENT(YLON).AND.PRESENT(YLAT))THEN
     LMAP=.TRUE.
   ELSE
     LMAP=.FALSE.
   ENDIF
   IF(PRESENT(AREA))THEN
     LAREA=.TRUE.
   ELSE
     LAREA=.FALSE.
   ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE GRID COORDINATES TO EARTH COORDINATES
   IF(IOPT.EQ.0.OR.IOPT.EQ.1) THEN
     DO N=1,NPTS
       IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND. &
          YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
         RLONR=WBD+(XPTS(N)-1._KD)*DLONS
         RLATR=SBD+(YPTS(N)-1._KD)*DLATS
         IF(RLONR <= 0._KD) THEN
           HS=-HI
         ELSE
           HS=HI
         ENDIF
         CLONR=COS(RLONR/DPR)
         SLATR=SIN(RLATR/DPR)
         CLATR=COS(RLATR/DPR)
         SLAT=CLAT0*SLATR+SLAT0*CLATR*CLONR
         IF(SLAT.LE.-1) THEN
           CLAT=0.
           CLON=COS(RLON0/DPR)
           RLON(N)=0
           RLAT(N)=-90
         ELSEIF(SLAT.GE.1) THEN
           CLAT=0.
           CLON=COS(RLON0/DPR)
           RLON(N)=0
           RLAT(N)=90
         ELSE
           CLAT=SQRT(1-SLAT**2)
           CLON=(CLAT0*CLATR*CLONR-SLAT0*SLATR)/CLAT
           CLON=MIN(MAX(CLON,-1._KD),1._KD)
           RLON(N)=MOD(RLON0+HS*DPR*ACOS(CLON)+3600,360._KD)
           RLAT(N)=DPR*ASIN(SLAT)
         ENDIF
         NRET=NRET+1
         IF(LROT) CALL GDSWZDCD_VECT_ROT(RLON(N), CROT(N), SROT(N))
         IF(LMAP) CALL GDSWZDCD_MAP_JACOB(FILL, RLON(N), &
                                          XLON(N), XLAT(N), YLON(N), YLAT(N))
         IF(LAREA) CALL GDSWZDCD_GRID_AREA(FILL, AREA(N))
       ELSE
         RLON(N)=FILL
         RLAT(N)=FILL
       ENDIF
     ENDDO
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE EARTH COORDINATES TO GRID COORDINATES
   ELSEIF(IOPT.EQ.-1) THEN
     DO N=1,NPTS
       IF(ABS(RLON(N)).LE.360.AND.ABS(RLAT(N)).LE.90) THEN
         HS=SIGN(1._KD,MOD(RLON(N)-RLON0+180+3600,360._KD)-180)
         CLON=COS((RLON(N)-RLON0)/DPR)
         SLAT=SIN(RLAT(N)/DPR)
         CLAT=COS(RLAT(N)/DPR)
         SLATR=CLAT0*SLAT-SLAT0*CLAT*CLON
         IF(SLATR.LE.-1) THEN
           CLATR=0.
           RLONR=0
           RLATR=-90
         ELSEIF(SLATR.GE.1) THEN
           CLATR=0.
           RLONR=0
           RLATR=90
         ELSE
           CLATR=SQRT(1-SLATR**2)
           CLONR=(CLAT0*CLAT*CLON+SLAT0*SLAT)/CLATR
           CLONR=MIN(MAX(CLONR,-1._KD),1._KD)
           RLONR=HS*DPR*ACOS(CLONR)
           RLATR=DPR*ASIN(SLATR)
         ENDIF
         XPTS(N)=(RLONR-WBD)/DLONS+1._KD
         YPTS(N)=(RLATR-SBD)/DLATS+1._KD
         IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND. &
            YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
           NRET=NRET+1
           IF(LROT) CALL GDSWZDCD_VECT_ROT(RLON(N), CROT(N), SROT(N))
           IF(LMAP) CALL GDSWZDCD_MAP_JACOB(FILL, RLON(N), &
                                            XLON(N), XLAT(N), YLON(N), YLAT(N))
           IF(LAREA) CALL GDSWZDCD_GRID_AREA(FILL, AREA(N))
         ELSE
           XPTS(N)=FILL
           YPTS(N)=FILL
         ENDIF
       ELSE
         XPTS(N)=FILL
         YPTS(N)=FILL
       ENDIF
     ENDDO
   ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  PROJECTION UNRECOGNIZED
 ELSE
   IF(IOPT.GE.0) THEN
     DO N=1,NPTS
       RLON(N)=FILL
       RLAT(N)=FILL
     ENDDO
   ENDIF
   IF(IOPT.LE.0) THEN
     DO N=1,NPTS
       XPTS(N)=FILL
       YPTS(N)=FILL
     ENDDO
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE GDSWZDCD
!
 SUBROUTINE GDSWZDCD_VECT_ROT(RLON, CROT, SROT)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZDCD_VECT_ROT   VECTOR ROTATION FIELDS FOR
!                                  ROTATED EQUIDISTANT CYLINDRICAL
!                                  GRIDS - NON "E" STAGGER.
!
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: THIS SUBPROGRAM COMPUTES THE VECTOR ROTATION SINES AND
!           COSINES FOR A ROTATED EQUIDISTANT CYLINDRICAL GRID -
!           NON "E" STAGGER.
!
! PROGRAM HISTORY LOG:
! 2015-01-21  GAYNO    INITIAL VERSION
!
! USAGE:    CALL GDSWZDCD_VECT_ROT(RLON, CROT, SROT)
!
!   INPUT ARGUMENT LIST:
!     RLON     - LONGITUDE IN DEGREES (REAL)
!
!   OUTPUT ARGUMENT LIST:
!     CROT     - CLOCKWISE VECTOR ROTATION COSINES (REAL)
!     SROT     - CLOCKWISE VECTOR ROTATION SINES (REAL)
!                (UGRID=CROT*UEARTH-SROT*VEARTH;
!                 VGRID=SROT*UEARTH+CROT*VEARTH)
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
 IMPLICIT NONE

 REAL         ,    INTENT(IN   ) :: RLON
 REAL         ,    INTENT(  OUT) :: CROT, SROT

 REAL(KIND=KD)                   :: SLON

 IF(IROT.EQ.1) THEN
   IF(CLATR.LE.0) THEN
     CROT=-SIGN(1._KD,SLATR*SLAT0)
     SROT=0.
   ELSE
     SLON=SIN((RLON-RLON0)/DPR)
     CROT=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
     SROT=SLAT0*SLON/CLATR
   ENDIF
 ELSE
   CROT=1.
   SROT=0.
 ENDIF

 END SUBROUTINE GDSWZDCD_VECT_ROT
!
 SUBROUTINE GDSWZDCD_MAP_JACOB(FILL, RLON, &
                               XLON, XLAT, YLON, YLAT)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZDCD_MAP_JACOB  MAP JACOBIANS FOR
!                                  ROTATED EQUIDISTANT CYLINDRICAL
!                                  GRIDS - NON "E" STAGGER.
!
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: THIS SUBPROGRAM COMPUTES THE MAP JACOBIANS FOR
!           A ROTATED EQUIDISTANT CYLINDRICAL GRID -
!           NON "E" STAGGER.
!
! PROGRAM HISTORY LOG:
! 2015-01-21  GAYNO    INITIAL VERSION
!
! USAGE:  CALL GDSWZDCD_MAP_JACOB(FILL,RLON,XLON,XLAT,YLON,YLAT)
!
!   INPUT ARGUMENT LIST:
!     FILL     - FILL VALUE FOR UNDEFINED POINTS (REAL)
!     RLON     - LONGITUDE IN DEGREES (REAL)
!
!   OUTPUT ARGUMENT LIST:
!     XLON     - DX/DLON IN 1/DEGREES (REAL)
!     XLAT     - DX/DLAT IN 1/DEGREES (REAL)
!     YLON     - DY/DLON IN 1/DEGREES (REAL)
!     YLAT     - DY/DLAT IN 1/DEGREES (REAL)
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
 IMPLICIT NONE

 REAL         ,    INTENT(IN   ) :: FILL, RLON
 REAL         ,    INTENT(  OUT) :: XLON, XLAT, YLON, YLAT

 REAL(KIND=KD)                   :: SLON, TERM1, TERM2

 IF(CLATR.LE.0._KD) THEN
   XLON=FILL
   XLAT=FILL
   YLON=FILL
   YLAT=FILL
 ELSE
   SLON=SIN((RLON-RLON0)/DPR)
   TERM1=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
   TERM2=SLAT0*SLON/CLATR
   XLON=TERM1*CLAT/(DLONS*CLATR)
   XLAT=-TERM2/(DLONS*CLATR)
   YLON=TERM2*CLAT/DLATS
   YLAT=TERM1/DLATS
 ENDIF

 END SUBROUTINE GDSWZDCD_MAP_JACOB
!
 SUBROUTINE GDSWZDCD_GRID_AREA(FILL, AREA)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZDCD_GRID_AREA  GRID BOX AREA FOR
!                                  ROTATED EQUIDISTANT CYLINDRICAL
!                                  GRIDS - NON "E" STAGGER.
!
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: THIS SUBPROGRAM COMPUTES THE GRID BOX AREA FOR
!           A ROTATED EQUIDISTANT CYLINDRICAL GRID -
!           NON "E" STAGGER.
!
! PROGRAM HISTORY LOG:
! 2015-01-21  GAYNO    INITIAL VERSION
!
! USAGE:  CALL GDSWZDCD_GRID_AREA(FILL,AREA)
!
!   INPUT ARGUMENT LIST:
!     FILL     - FILL VALUE FOR UNDEFINED POINTS (REAL)
!
!   OUTPUT ARGUMENT LIST:
!     AREA     - AREA WEIGHTS IN M**2 (REAL)
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
 IMPLICIT NONE

 REAL,             INTENT(IN   ) :: FILL
 REAL,             INTENT(  OUT) :: AREA

 IF(CLATR.LE.0._KD) THEN
   AREA=FILL
 ELSE
   AREA=2._KD*(RERTH**2)*CLATR*(DLONS/DPR)*SIN(0.5_KD*DLATS/DPR)
 ENDIF

 END SUBROUTINE GDSWZDCD_GRID_AREA

 END MODULE GDSWZDCD_MOD

 MODULE GDSWZD00_MOD
!$$$  MODULE DOCUMENTATION BLOCK
!
! $Revision$
!
! MODULE:  GDSWZD00_MOD  GDS WIZARD MODULE FOR EQUIDISTANT CYLINDRICAL GRIDS
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: - CONVERT FROM EARTH TO GRID COORDINATES OR VICE VERSA.
!           - COMPUTE VECTOR ROTATION SINES AND COSINES.
!           - COMPUTE MAP JACOBIANS.
!           - COMPUTE GRID BOX AREA.
!
! PROGRAM HISTORY LOG:
!   2015-01-21  GAYNO   INITIAL VERSION FROM A MERGER OF
!                       ROUTINES GDSWIZ00 AND GDSWZD00.
!
! USAGE:  "USE GDSWZD00_MOD"  THEN CALL THE PUBLIC DRIVER
!         ROUTINE "GDSWZD00".
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
 IMPLICIT NONE

 PRIVATE

 PUBLIC                  :: GDSWZD00

 REAL                    :: DLAT ! GRID RESOLUTION IN DEGREES N/S DIRECTION
 REAL                    :: DLON ! GRID RESOLUTION IN DEGREES E/W DIRECTION

 CONTAINS

 SUBROUTINE GDSWZD00(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET,  &
                     CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZD00   GDS WIZARD FOR EQUIDISTANT CYLINDRICAL
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: DRIVER ROUTINE THAT DECODES THE GRIB GRID DESCRIPTION SECTION
!           (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63)
!           AND RETURNS ONE OF THE FOLLOWING:
!             (IOPT=+1) EARTH COORDINATES OF SELECTED GRID COORDINATES
!             (IOPT=-1) GRID COORDINATES OF SELECTED EARTH COORDINATES
!           FOR EQUIDISTANT CYLINDRICAL PROJECTIONS.
!           IF THE SELECTED COORDINATES ARE MORE THAN ONE GRIDPOINT
!           BEYOND THE THE EDGES OF THE GRID DOMAIN, THEN THE RELEVANT
!           OUTPUT ELEMENTS ARE SET TO FILL VALUES.
!           THE ACTUAL NUMBER OF VALID POINTS COMPUTED IS RETURNED TOO.
!           OPTIONALLY, THE VECTOR ROTATIONS, MAP JACOBIANS AND
!           GRID BOX AREAS MAY BE RETURNED AS WELL.  TO COMPUTE
!           THE VECTOR ROTATIONS, THE OPTIONAL ARGUMENTS 'SROT' AND 'CROT'
!           MUST BE PRESENT.  TO COMPUTE THE MAP JACOBIANS, THE
!           OPTIONAL ARGUMENTS 'XLON', 'XLAT', 'YLON', 'YLAT' MUST BE PRESENT.
!           TO COMPUTE THE GRID BOX AREAS, THE OPTIONAL ARGUMENT
!           'AREA' MUST BE PRESENT.
!
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
!   97-10-20  IREDELL  INCLUDE MAP OPTIONS
! 2015-01-21  GAYNO    MERGER OF GDSWIZ00 AND GDSWZD00.  MAKE
!                      CROT,SORT,XLON,XLAT,YLON,YLAT AND AREA
!                      OPTIONAL ARGUMENTS.  MAKE PART OF A MODULE. 
!                      MOVE VECTOR ROTATION, MAP JACOBIAN AND GRID
!                      BOX AREA COMPUTATIONS TO SEPARATE SUBROUTINES.
!
! USAGE:    CALL GDSWZD00(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET,
!    &                    CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
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
 INTEGER,             INTENT(IN   ) :: IOPT, KGDS(200), NPTS
 INTEGER,             INTENT(  OUT) :: NRET
!
 REAL,                INTENT(IN   ) :: FILL
 REAL,                INTENT(INOUT) :: RLON(NPTS),RLAT(NPTS)
 REAL,                INTENT(INOUT) :: XPTS(NPTS),YPTS(NPTS)
 REAL, OPTIONAL,      INTENT(  OUT) :: CROT(NPTS),SROT(NPTS)
 REAL, OPTIONAL,      INTENT(  OUT) :: XLON(NPTS),XLAT(NPTS)
 REAL, OPTIONAL,      INTENT(  OUT) :: YLON(NPTS),YLAT(NPTS),AREA(NPTS)
!
 INTEGER                            :: IM, JM, ISCAN, N
!
 LOGICAL                            :: LROT, LMAP, LAREA
!
 REAL                               :: HI, RLAT1, RLON1, RLAT2, RLON2
 REAL                               :: XMAX, XMIN, YMAX, YMIN
!
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 IF(PRESENT(CROT)) CROT=FILL
 IF(PRESENT(SROT)) SROT=FILL
 IF(PRESENT(XLON)) XLON=FILL
 IF(PRESENT(XLAT)) XLAT=FILL
 IF(PRESENT(YLON)) YLON=FILL
 IF(PRESENT(YLAT)) YLAT=FILL
 IF(PRESENT(AREA)) AREA=FILL
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 IF(KGDS(1).EQ.000) THEN
   IM=KGDS(2)
   JM=KGDS(3)
   RLAT1=KGDS(4)*1.E-3
   RLON1=KGDS(5)*1.E-3
   RLAT2=KGDS(7)*1.E-3
   RLON2=KGDS(8)*1.E-3
   ISCAN=MOD(KGDS(11)/128,2)
   HI=(-1.)**ISCAN
   DLON=HI*(MOD(HI*(RLON2-RLON1)-1+3600,360.)+1)/(IM-1)
   DLAT=(RLAT2-RLAT1)/(JM-1)
   XMIN=0
   XMAX=IM+1
   IF(IM.EQ.NINT(360/ABS(DLON))) XMAX=IM+2
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
         RLON(N)=MOD(RLON1+DLON*(XPTS(N)-1)+3600,360.)
         RLAT(N)=MIN(MAX(RLAT1+DLAT*(YPTS(N)-1),-90.),90.)
         NRET=NRET+1
         IF(LROT)  CALL GDSWZD00_VECT_ROT(CROT(N),SROT(N))
         IF(LMAP)  CALL GDSWZD00_MAP_JACOB(XLON(N),XLAT(N),YLON(N),YLAT(N))
         IF(LAREA) CALL GDSWZD00_GRID_AREA(RLAT(N),AREA(N))
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
         XPTS(N)=1+HI*MOD(HI*(RLON(N)-RLON1)+3600,360.)/DLON
         YPTS(N)=1+(RLAT(N)-RLAT1)/DLAT
         IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND.  &
            YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
           NRET=NRET+1
           IF(LROT)  CALL GDSWZD00_VECT_ROT(CROT(N),SROT(N))
           IF(LMAP)  CALL GDSWZD00_MAP_JACOB(XLON(N),XLAT(N),YLON(N),YLAT(N))
           IF(LAREA) CALL GDSWZD00_GRID_AREA(RLAT(N),AREA(N))
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
 END SUBROUTINE GDSWZD00
!
 SUBROUTINE GDSWZD00_VECT_ROT(CROT,SROT)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZD00_VECT_ROT   VECTOR ROTATION FIELDS FOR 
!                                  EQUIDISTANT CYLINDRICAL GRIDS
!
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: THIS SUBPROGRAM COMPUTES THE VECTOR ROTATION SINES AND
!           COSINES FOR AN EQUIDISTANT CYLINDRICAL GRID.
!
! PROGRAM HISTORY LOG:
! 2015-01-21  GAYNO    INITIAL VERSION
!
! USAGE:    CALL GDSWZD00_VECT_ROT(CROT,SROT)
! 
!   INPUT ARGUMENT LIST:
!     NONE
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
 IMPLICIT NONE

 REAL,                INTENT(  OUT) :: CROT, SROT

 CROT=1.0
 SROT=0.0

 END SUBROUTINE GDSWZD00_VECT_ROT
!
 SUBROUTINE GDSWZD00_MAP_JACOB(XLON,XLAT,YLON,YLAT)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZD00_MAP_JACOB  MAP JACOBIANS FOR 
!                                  EQUIDISTANT CYLINDRICAL GRIDS
!
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: THIS SUBPROGRAM COMPUTES THE MAP JACOBIANS FOR
!           AN EQUIDISTANT CYLINDRICAL GRID.
!
! PROGRAM HISTORY LOG:
! 2015-01-21  GAYNO    INITIAL VERSION
!
! USAGE:  CALL GDSWZD00_MAP_JACOB(XLON,XLAT,YLON,YLAT)
! 
!   INPUT ARGUMENT LIST:
!     NONE
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

 REAL,                INTENT(  OUT) :: XLON,XLAT,YLON,YLAT

 XLON=1.0/DLON
 XLAT=0.
 YLON=0.
 YLAT=1.0/DLAT

 END SUBROUTINE GDSWZD00_MAP_JACOB
!
 SUBROUTINE GDSWZD00_GRID_AREA(RLAT,AREA)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWZD00_GRID_AREA  GRID BOX AREA FOR 
!                                  EQUIDISTANT CYLINDRICAL GRIDS
!
!   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
!
! ABSTRACT: THIS SUBPROGRAM COMPUTES THE GRID BOX AREA FOR
!           AN EQUIDISTANT CYLINDRICAL GRID.
!
! PROGRAM HISTORY LOG:
! 2015-01-21  GAYNO    INITIAL VERSION
!
! USAGE:  CALL GDSWZD00_GRID_AREA(RLAT,AREA)
! 
!   INPUT ARGUMENT LIST:
!     RLAT     - LATITUDE OF GRID POINT IN DEGREES (REAL)
!
!   OUTPUT ARGUMENT LIST:
!     AREA     - AREA WEIGHTS IN M**2 (REAL)
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE

 REAL,                INTENT(IN   ) :: RLAT
 REAL,                INTENT(  OUT) :: AREA

 REAL,                PARAMETER     :: RERTH=6.3712E6
 REAL,                PARAMETER     :: PI=3.14159265358979
 REAL,                PARAMETER     :: DPR=180./PI

 REAL                               :: DSLAT, RLATU, RLATD

 RLATU=MIN(MAX(RLAT+DLAT/2,-90.),90.)
 RLATD=MIN(MAX(RLAT-DLAT/2,-90.),90.)
 DSLAT=SIN(RLATU/DPR)-SIN(RLATD/DPR)
 AREA=RERTH**2*ABS(DSLAT*DLON)/DPR

 END SUBROUTINE GDSWZD00_GRID_AREA

 END MODULE GDSWZD00_MOD

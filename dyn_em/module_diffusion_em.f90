




 
    MODULE module_diffusion_em

    USE module_bc, only: set_physical_bc3d
    USE module_state_description, only: p_m23, p_m13, p_m22, p_m33, p_r23, p_r13, p_r12, p_m12, p_m11
    USE module_big_step_utilities_em, only: grid_config_rec_type, param_first_scalar, p_qv, p_qi, p_qc
    USE module_model_constants    

    CONTAINS




    SUBROUTINE cal_deform_and_div( config_flags, u, v, w, div,       &
                                   defor11, defor22, defor33,        &
                                   defor12, defor13, defor23,        &
                                   nba_rij, n_nba_rij,               & 
                                   u_base, v_base, msfux, msfuy,     &
                                   msfvx, msfvy, msftx, msfty,       &
                                   rdx, rdy, dn, dnw, rdz, rdzw,     &
                                   fnm, fnp, cf1, cf2, cf3, zx, zy,  &
                                   ids, ide, jds, jde, kds, kde,     &
                                   ims, ime, jms, jme, kms, kme,     &
                                   its, ite, jts, jte, kts, kte      )


























    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde, &
       ims, ime, jms, jme, kms, kme, &
       its, ite, jts, jte, kts, kte

    REAL, INTENT( IN )  &
    :: rdx, rdy, cf1, cf2, cf3

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: fnm, fnp, dn, dnw, u_base, v_base

    REAL, DIMENSION( ims:ime , jms:jme ),  INTENT( IN )  &
    :: msfux, msfuy, msfvx, msfvy, msftx, msfty

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    ::  u, v, w, zx, zy, rdz, rdzw

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: defor11, defor22, defor33, defor12, defor13, defor23, div 

   INTEGER, INTENT(  IN ) :: n_nba_rij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_rij), INTENT(INOUT) & 
   :: nba_rij




    INTEGER  &
    :: i, j, k, ktf, ktes1, ktes2, i_start, i_end, j_start, j_end

    REAL  &
    :: tmp, tmpzx, tmpzy, tmpzeta_z, cft1, cft2

    REAL, DIMENSION( its:ite, jts:jte )  &
    :: mm, zzavg, zeta_zd12

    REAL, DIMENSION( its-2:ite+2, kts:kte, jts-2:jte+2 )  &
    :: tmp1, hat, hatavg















    ktes1   = kte-1
    ktes2   = kte-2

    cft2    = - 0.5 * dnw(ktes1) / dn(ktes1)
    cft1    = 1.0 - cft2

    ktf     = MIN( kte, kde-1 )

    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )



    DO j = j_start, j_end
    DO i = i_start, i_end
      mm(i,j) = msftx(i,j) * msfty(i,j)
    END DO
    END DO






    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end+1
      hat(i,k,j) = u(i,k,j) / msfuy(i,j)
    END DO
    END DO
    END DO



    DO j=j_start,j_end
    DO k=kts+1,ktf
    DO i=i_start,i_end
      hatavg(i,k,j) = 0.5 *  &
                    ( fnm(k) * ( hat(i,k  ,j) + hat(i+1,  k,j) ) +  &
                      fnp(k) * ( hat(i,k-1,j) + hat(i+1,k-1,j) ) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO i = i_start, i_end
      hatavg(i,1,j)   =  0.5 * (  &
                         cf1 * hat(i  ,1,j) +  &
                         cf2 * hat(i  ,2,j) +  &
                         cf3 * hat(i  ,3,j) +  &
                         cf1 * hat(i+1,1,j) +  &
                         cf2 * hat(i+1,2,j) +  &
                         cf3 * hat(i+1,3,j) )
      hatavg(i,kte,j) =  0.5 * (  &
                        cft1 * ( hat(i,ktes1,j) + hat(i+1,ktes1,j) )  +  &
                        cft2 * ( hat(i,ktes2,j) + hat(i+1,ktes2,j) ) )
    END DO
    END DO

    
    
    
    
    

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmpzx       = 0.25 * (  &
                    zx(i,k  ,j) + zx(i+1,k  ,j) +  &
                    zx(i,k+1,j) + zx(i+1,k+1,j) )
      tmp1(i,k,j) = ( hatavg(i,k+1,j) - hatavg(i,k,j) ) *tmpzx * rdzw(i,k,j)
      
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmp1(i,k,j) = mm(i,j) * ( rdx * ( hat(i+1,k,j) - hat(i,k,j) ) -  &
                    tmp1(i,k,j))
    END DO
    END DO
    END DO










    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      defor11(i,k,j) = 2.0 * tmp1(i,k,j)
    END DO
    END DO
    END DO







    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      div(i,k,j) = tmp1(i,k,j)
    END DO
    END DO
    END DO









    DO j = j_start, j_end+1
    DO k = kts, ktf
    DO i = i_start, i_end
      
      
      
      IF ((config_flags%polar) .AND. ((j == jds) .OR. (j == jde))) THEN
         hat(i,k,j) = 0.
      ELSE 
      hat(i,k,j) = v(i,k,j) / msfvx(i,j)
      ENDIF
    END DO
    END DO
    END DO



    DO j=j_start,j_end
    DO k=kts+1,ktf
    DO i=i_start,i_end
      hatavg(i,k,j) = 0.5 * (  &
                      fnm(k) * ( hat(i,k  ,j) + hat(i,k  ,j+1) ) +  &
                      fnp(k) * ( hat(i,k-1,j) + hat(i,k-1,j+1) ) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO i = i_start, i_end
      hatavg(i,1,j)   =  0.5 * (  &
                         cf1 * hat(i,1,j  ) +  &
                         cf2 * hat(i,2,j  ) +  &
                         cf3 * hat(i,3,j  ) +  &
                         cf1 * hat(i,1,j+1) +  &
                         cf2 * hat(i,2,j+1) +  &
                         cf3 * hat(i,3,j+1) )
      hatavg(i,kte,j) =  0.5 * (  &
                        cft1 * ( hat(i,ktes1,j) + hat(i,ktes1,j+1) ) +  &
                        cft2 * ( hat(i,ktes2,j) + hat(i,ktes2,j+1) ) )
    END DO
    END DO

    
    
    
    
    

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmpzy       =  0.25 * (  &
                     zy(i,k  ,j) + zy(i,k  ,j+1) +  &
                     zy(i,k+1,j) + zy(i,k+1,j+1)  )
      tmp1(i,k,j) = ( hatavg(i,k+1,j) - hatavg(i,k,j) ) * tmpzy * rdzw(i,k,j)
      
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmp1(i,k,j) = mm(i,j) * (  &
                    rdy * ( hat(i,k,j+1) - hat(i,k,j) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO










    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      defor22(i,k,j) = 2.0 * tmp1(i,k,j)
    END DO
    END DO
    END DO








    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      div(i,k,j) = div(i,k,j) + tmp1(i,k,j)
    END DO
    END DO
    END DO












    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmp1(i,k,j) = ( w(i,k+1,j) - w(i,k,j) ) * rdzw(i,k,j)
    END DO
    END DO
    END DO







    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      defor33(i,k,j) = 2.0 * tmp1(i,k,j)
    END DO
    END DO
    END DO








    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      div(i,k,j) = div(i,k,j) + tmp1(i,k,j)
    END DO
    END DO
    END DO



















    i_start = its
    i_end   = ite
    j_start = jts
    j_end   = jte

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. & 
         config_flags%nested) i_end   = MIN( ide-1, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-1, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = ite













    DO j = j_start, j_end
    DO i = i_start, i_end
      mm(i,j) = 0.25 * ( msfux(i,j-1) + msfux(i,j) ) * ( msfvy(i-1,j) + msfvy(i,j) )
    END DO
    END DO



    DO j =j_start-1, j_end
    DO k =kts, ktf
    DO i =i_start, i_end
      
      
      hat(i,k,j) = u(i,k,j) / msfux(i,j)
    END DO
    END DO
    END DO



    DO j=j_start,j_end
    DO k=kts+1,ktf
    DO i=i_start,i_end
      hatavg(i,k,j) = 0.5 * (  &
                      fnm(k) * ( hat(i,k  ,j-1) + hat(i,k  ,j) ) +  &
                      fnp(k) * ( hat(i,k-1,j-1) + hat(i,k-1,j) ) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO i = i_start, i_end
      hatavg(i,1,j)   =  0.5 * (  &
                         cf1 * hat(i,1,j-1) +  &
                         cf2 * hat(i,2,j-1) +  &
                         cf3 * hat(i,3,j-1) +  &
                         cf1 * hat(i,1,j  ) +  &
                         cf2 * hat(i,2,j  ) +  &
                         cf3 * hat(i,3,j  ) )
      hatavg(i,kte,j) =  0.5 * (  &
                        cft1 * ( hat(i,ktes1,j-1) + hat(i,ktes1,j) ) +  &
                        cft2 * ( hat(i,ktes2,j-1) + hat(i,ktes2,j) ) )
    END DO
    END DO

    
    
    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmpzy       = 0.25 * (  &
                    zy(i-1,k  ,j) + zy(i,k  ,j) +  &
                    zy(i-1,k+1,j) + zy(i,k+1,j) )
      tmp1(i,k,j) = ( hatavg(i,k+1,j) - hatavg(i,k,j) ) *  &
                    0.25 * tmpzy * ( rdzw(i,k,j) + rdzw(i-1,k,j) + &
                                     rdzw(i-1,k,j-1) + rdzw(i,k,j-1) )
    END DO
    END DO
    END DO















    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      defor12(i,k,j) = mm(i,j) * (  &
                       rdy * ( hat(i,k,j) - hat(i,k,j-1) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO









    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start-1, i_end
       hat(i,k,j) = v(i,k,j) / msfvy(i,j)
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      hatavg(i,k,j) = 0.5 * (  &
                      fnm(k) * ( hat(i-1,k  ,j) + hat(i,k  ,j) ) +  &
                      fnp(k) * ( hat(i-1,k-1,j) + hat(i,k-1,j) ) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO i = i_start, i_end
       hatavg(i,1,j)   =  0.5 * (  &
                          cf1 * hat(i-1,1,j) +  &
                          cf2 * hat(i-1,2,j) +  &
                          cf3 * hat(i-1,3,j) +  &
                          cf1 * hat(i  ,1,j) +  &
                          cf2 * hat(i  ,2,j) +  &
                          cf3 * hat(i  ,3,j) )
       hatavg(i,kte,j) =  0.5 * (  &
                         cft1 * ( hat(i,ktes1,j) + hat(i-1,ktes1,j) ) +  &
                         cft2 * ( hat(i,ktes2,j) + hat(i-1,ktes2,j) ) )
    END DO
    END DO

    
    
    
    
    
    
    
    
    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmpzx       = 0.25 * (  &
                    zx(i,k  ,j-1) + zx(i,k  ,j) +  &
                    zx(i,k+1,j-1) + zx(i,k+1,j) )
      tmp1(i,k,j) = ( hatavg(i,k+1,j) - hatavg(i,k,j) ) *  &
                    0.25 * tmpzx * ( rdzw(i,k,j) + rdzw(i,k,j-1) + &
                                     rdzw(i-1,k,j-1) + rdzw(i-1,k,j) )
    END DO
    END DO
    END DO














  IF ( config_flags%sfs_opt .GT. 0 ) THEN 













    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end

      nba_rij(i,k,j,P_r12) = defor12(i,k,j) -  &    
                             mm(i,j) * (   &                            
                             rdx * ( hat(i,k,j) - hat(i-1,k,j) ) - tmp1(i,k,j) ) 

      defor12(i,k,j) = defor12(i,k,j) +  &
                       mm(i,j) * (  &
                       rdx * ( hat(i,k,j) - hat(i-1,k,j) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO






 
    IF ( .NOT. config_flags%periodic_x .AND. i_start .EQ. ids+1 ) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor12(ids,k,j) = defor12(ids+1,k,j)
        nba_rij(ids,k,j,P_r12) = nba_rij(ids+1,k,j,P_r12) 
      END DO
      END DO
    END IF
 
    IF ( .NOT. config_flags%periodic_y .AND. j_start .EQ. jds+1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor12(i,k,jds) = defor12(i,k,jds+1)
        nba_rij(i,k,jds,P_r12) = nba_rij(i,k,jds+1,P_r12) 
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_x .AND. i_end .EQ. ide-1) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor12(ide,k,j) = defor12(ide-1,k,j)
        nba_rij(ide,k,j,P_r12) = nba_rij(ide-1,k,j,P_r12) 
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_end .EQ. jde-1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor12(i,k,jde) = defor12(i,k,jde-1)
        nba_rij(i,k,jde,P_r12) = nba_rij(i,k,jde-1,P_r12) 
      END DO
      END DO
    END IF

  ELSE 

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      defor12(i,k,j) = defor12(i,k,j) +  &
                       mm(i,j) * (  &
                       rdx * ( hat(i,k,j) - hat(i-1,k,j) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO






 
    IF ( .NOT. config_flags%periodic_x .AND. i_start .EQ. ids+1 ) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor12(ids,k,j) = defor12(ids+1,k,j)
      END DO
      END DO
    END IF
 
    IF ( .NOT. config_flags%periodic_y .AND. j_start .EQ. jds+1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor12(i,k,jds) = defor12(i,k,jds+1)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_x .AND. i_end .EQ. ide-1) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor12(ide,k,j) = defor12(ide-1,k,j)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_end .EQ. jde-1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor12(i,k,jde) = defor12(i,k,jde-1)
      END DO
      END DO
    END IF

  ENDIF 













    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )

    IF ( config_flags%periodic_x ) i_start = its
    IF ( config_flags%periodic_x ) i_end = MIN( ite, ide )
    IF ( config_flags%periodic_y ) j_end = MIN( jte, jde )



    DO j = jts, jte
    DO i = its, ite
      mm(i,j) = msfux(i,j) * msfuy(i,j)
    END DO
    END DO




    DO j = j_start, j_end
    DO k = kts, kte
    DO i = i_start, i_end
      hat(i,k,j) = w(i,k,j) / msfty(i,j)
    END DO
    END DO
    END DO

    i = i_start-1
    DO j = j_start, MIN( jte, jde-1 )
    DO k = kts, kte
      hat(i,k,j) = w(i,k,j) / msfty(i,j)
    END DO
    END DO

    j = j_start-1
    DO k = kts, kte
    DO i = i_start, MIN( ite, ide-1 )
      hat(i,k,j) = w(i,k,j) / msfty(i,j)
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      hatavg(i,k,j) = 0.25 * (  &
                      hat(i  ,k  ,j) +  &
                      hat(i  ,k+1,j) +  &
                      hat(i-1,k  ,j) +  &
                      hat(i-1,k+1,j) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      tmp1(i,k,j) = ( hatavg(i,k,j) - hatavg(i,k-1,j) ) * zx(i,k,j) *  &
                    0.5 * ( rdz(i,k,j) + rdz(i-1,k,j) )
    END DO
    END DO
    END DO








    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      defor13(i,k,j) = mm(i,j) * (  &
                       rdx * ( hat(i,k,j) - hat(i-1,k,j) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO i = i_start, i_end
      defor13(i,kts,j  ) = 0.0
      defor13(i,ktf+1,j) = 0.0
    END DO
    END DO







    IF ( config_flags%mix_full_fields ) THEN

      DO j = j_start, j_end
      DO k = kts+1, ktf
      DO i = i_start, i_end
        tmp1(i,k,j) = ( u(i,k,j) - u(i,k-1,j) ) *  &
                      0.5 * ( rdz(i,k,j) + rdz(i-1,k,j) )
      END DO
      END DO
      END DO

    ELSE

      DO j = j_start, j_end
      DO k = kts+1, ktf
      DO i = i_start, i_end
        tmp1(i,k,j) = ( u(i,k,j) - u_base(k) - u(i,k-1,j) + u_base(k-1) ) *  &
                      0.5 * ( rdz(i,k,j) + rdz(i-1,k,j) )
      END DO
      END DO
      END DO

    END IF






  IF ( config_flags%sfs_opt .GT. 0 ) THEN 












    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      nba_rij(i,k,j,P_r13) =  tmp1(i,k,j) - defor13(i,k,j)   
      defor13(i,k,j) = defor13(i,k,j) + tmp1(i,k,j)
    END DO
    END DO
    END DO

    DO j = j_start, j_end 
    DO i = i_start, i_end
      nba_rij(i,kts  ,j,P_r13) = 0.0
      nba_rij(i,ktf+1,j,P_r13) = 0.0
    END DO
    END DO

  ELSE 

    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      defor13(i,k,j) = defor13(i,k,j) + tmp1(i,k,j)
    END DO
    END DO
    END DO

  ENDIF 







    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%periodic_y ) j_end = MIN( jte, jde )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )



    DO j = jts, jte
    DO i = its, ite
      mm(i,j) = msfvx(i,j) * msfvy(i,j)
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts, kte
    DO i = i_start, i_end
      hat(i,k,j) = w(i,k,j) / msftx(i,j)
    END DO
    END DO
    END DO

    i = i_start-1
    DO j = j_start, MIN( jte, jde-1 )
    DO k = kts, kte
      hat(i,k,j) = w(i,k,j) / msftx(i,j)
    END DO
    END DO

    j = j_start-1
    DO k = kts, kte
    DO i = i_start, MIN( ite, ide-1 )
      hat(i,k,j) = w(i,k,j) / msftx(i,j)
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      hatavg(i,k,j) = 0.25 * (  &
                      hat(i,k  ,j  ) +  &
                      hat(i,k+1,j  ) +  &
                      hat(i,k  ,j-1) +  &
                      hat(i,k+1,j-1) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      tmp1(i,k,j) = ( hatavg(i,k,j) - hatavg(i,k-1,j) ) * zy(i,k,j) *  &
                    0.5 * ( rdz(i,k,j) + rdz(i,k,j-1) )
    END DO
    END DO
    END DO








    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      defor23(i,k,j) = mm(i,j) * (  &
                       rdy * ( hat(i,k,j) - hat(i,k,j-1) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO i = i_start, i_end
      defor23(i,kts,j  ) = 0.0
      defor23(i,ktf+1,j) = 0.0
    END DO
    END DO







    IF ( config_flags%mix_full_fields ) THEN

      DO j = j_start, j_end
      DO k = kts+1, ktf
      DO i = i_start, i_end
        tmp1(i,k,j) = ( v(i,k,j) - v(i,k-1,j) ) *  &
                      0.5 * ( rdz(i,k,j) + rdz(i,k,j-1) )
      END DO
      END DO
      END DO

    ELSE

      DO j = j_start, j_end
      DO k = kts+1, ktf
      DO i = i_start, i_end
        tmp1(i,k,j) = ( v(i,k,j) - v_base(k) - v(i,k-1,j) + v_base(k-1) ) *  &
                      0.5 * ( rdz(i,k,j) + rdz(i,k,j-1) )
      END DO
      END DO
      END DO

    END IF








  IF ( config_flags%sfs_opt .GT. 0 ) THEN 













    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      nba_rij(i,k,j,P_r23) = tmp1(i,k,j) - defor23(i,k,j)  
      defor23(i,k,j) = defor23(i,k,j) + tmp1(i,k,j)
    END DO
    END DO
    END DO

    DO j = j_start, j_end
      DO i = i_start, i_end
        nba_rij(i,kts  ,j,P_r23) = 0.0
        nba_rij(i,ktf+1,j,P_r23) = 0.0
      END DO
    END DO








    IF ( .NOT. config_flags%periodic_x .AND. i_start .EQ. ids+1) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor13(ids,k,j) = defor13(ids+1,k,j)
        defor23(ids,k,j) = defor23(ids+1,k,j)
        nba_rij(ids,k,j,P_r13) = nba_rij(ids+1,k,j,P_r13) 
        nba_rij(ids,k,j,P_r23) = nba_rij(ids+1,k,j,P_r23) 
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_start .EQ. jds+1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor13(i,k,jds) = defor13(i,k,jds+1)
        defor23(i,k,jds) = defor23(i,k,jds+1)
        nba_rij(i,k,jds,P_r13) = nba_rij(i,k,jds+1,P_r13) 
        nba_rij(i,k,jds,P_r23) = nba_rij(i,k,jds+1,P_r23) 
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_x .AND. i_end .EQ. ide-1) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor13(ide,k,j) = defor13(ide-1,k,j)
        defor23(ide,k,j) = defor23(ide-1,k,j)
        nba_rij(ide,k,j,P_r13) = nba_rij(ide-1,k,j,P_r13) 
        nba_rij(ide,k,j,P_r23) = nba_rij(ide-1,k,j,P_r23) 
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_end .EQ. jde-1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor13(i,k,jde) = defor13(i,k,jde-1)
        defor23(i,k,jde) = defor23(i,k,jde-1)
        nba_rij(i,k,jde,P_r13) = nba_rij(i,k,jde-1,P_r13) 
        nba_rij(i,k,jde,P_r23) = nba_rij(i,k,jde-1,P_r23) 
      END DO
      END DO
    END IF

  ELSE 



    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      defor23(i,k,j) = defor23(i,k,j) + tmp1(i,k,j)
    END DO
    END DO
    END DO








    IF ( .NOT. config_flags%periodic_x .AND. i_start .EQ. ids+1) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor13(ids,k,j) = defor13(ids+1,k,j)
        defor23(ids,k,j) = defor23(ids+1,k,j)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_start .EQ. jds+1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor13(i,k,jds) = defor13(i,k,jds+1)
        defor23(i,k,jds) = defor23(i,k,jds+1)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_x .AND. i_end .EQ. ide-1) THEN
      DO j = jts, jte
      DO k = kts, kte
        defor13(ide,k,j) = defor13(ide-1,k,j)
        defor23(ide,k,j) = defor23(ide-1,k,j)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_end .EQ. jde-1) THEN
      DO k = kts, kte
      DO i = its, ite
        defor13(i,k,jde) = defor13(i,k,jde-1)
        defor23(i,k,jde) = defor23(i,k,jde-1)
      END DO
      END DO
    END IF

  ENDIF 








    END SUBROUTINE cal_deform_and_div




    SUBROUTINE calculate_km_kh( config_flags, dt,                        &
                                dampcoef, zdamp, damp_opt,               &
                                xkmh, xkmv, xkhh, xkhv,                  &
                                BN2, khdif, kvdif, div,                  &
                                defor11, defor22, defor33,               &
                                defor12, defor13, defor23,               &
                                tke, p8w, t8w, theta, t, p, moist,       &
                                dn, dnw, dx, dy, rdz, rdzw, isotropic,   &
                                n_moist, cf1, cf2, cf3, warm_rain,       &
                                mix_upper_bound,                         &
                                msftx, msfty,                            &
                                zx, zy,                                  &
                                ids, ide, jds, jde, kds, kde,            &
                                ims, ime, jms, jme, kms, kme,            &
                                its, ite, jts, jte, kts, kte             )















    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags   

    INTEGER, INTENT( IN )  &
    :: n_moist, damp_opt, isotropic,  & 
       ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte 

    LOGICAL, INTENT( IN )  &
    :: warm_rain

    REAL, INTENT( IN )  &
    :: dx, dy, zdamp, dt, dampcoef, cf1, cf2, cf3, khdif, kvdif

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: dnw, dn

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme, n_moist ), INTENT( INOUT )  &
    :: moist

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: xkmv, xkmh, xkhv, xkhh, BN2  

    REAL, DIMENSION( ims:ime , kms:kme, jms:jme ),  INTENT( IN )  &
    :: defor11, defor22, defor33, defor12, defor13, defor23,      &
       div, rdz, rdzw, p8w, t8w, theta, t, p, zx, zy

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: tke

    REAL, INTENT( IN )  &
    :: mix_upper_bound

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: msftx, msfty



    INTEGER  &
    :: i_start, i_end, j_start, j_end, ktf, i, j, k




    ktf     = MIN( kte, kde-1 )
    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    CALL calculate_N2( config_flags, BN2, moist,           &
                       theta, t, p, p8w, t8w,              &
                       dnw, dn, rdz, rdzw,                 &
                       n_moist, cf1, cf2, cf3, warm_rain,  &
                       ids, ide, jds, jde, kds, kde,       &
                       ims, ime, jms, jme, kms, kme,       &
                       its, ite, jts, jte, kts, kte        )



    km_coef: SELECT CASE( config_flags%km_opt )

      CASE (1)
            CALL isotropic_km( config_flags, xkmh, xkmv,                &
                               xkhh, xkhv, khdif, kvdif,                &
                               ids, ide, jds, jde, kds, kde,            &
                               ims, ime, jms, jme, kms, kme,            &
                               its, ite, jts, jte, kts, kte             )
      CASE (2)  
            CALL tke_km(       config_flags, xkmh, xkmv,                &
                               xkhh, xkhv, BN2, tke, p8w, t8w, theta,   &
                               rdz, rdzw, dx, dy, dt, isotropic,        &
                               mix_upper_bound, msftx, msfty,           &
                               ids, ide, jds, jde, kds, kde,            &
                               ims, ime, jms, jme, kms, kme,            &
                               its, ite, jts, jte, kts, kte             )
      CASE (3)  
            CALL smag_km(      config_flags, xkmh, xkmv,                &
                               xkhh, xkhv, BN2, div,                    &
                               defor11, defor22, defor33,               &
                               defor12, defor13, defor23,               &
                               rdzw, dx, dy, dt, isotropic,             &
                               mix_upper_bound, msftx, msfty,           &
                               ids, ide, jds, jde, kds, kde,            &
                               ims, ime, jms, jme, kms, kme,            &
                               its, ite, jts, jte, kts, kte             )
      CASE (4)  
            CALL smag2d_km(    config_flags, xkmh, xkmv,                &
                               xkhh, xkhv, defor11, defor22, defor12,   &
                               rdzw, dx, dy, msftx, msfty,              &
                               zx, zy,                                  &
                               ids, ide, jds, jde, kds, kde,            &
                               ims, ime, jms, jme, kms, kme,            &
                               its, ite, jts, jte, kts, kte             )
      CASE DEFAULT
            CALL wrf_error_fatal3("<stdin>",1323,&
'Please choose diffusion coefficient scheme' )

    END SELECT km_coef

    IF ( damp_opt .eq. 1 ) THEN
      CALL cal_dampkm( config_flags, xkmh, xkhh, xkmv, xkhv,    &
                       dx, dy, dt, dampcoef, rdz, rdzw, zdamp,  &
                       msftx, msfty,                            &
                       ids, ide, jds, jde, kds, kde,            &
                       ims, ime, jms, jme, kms, kme,            &
                       its, ite, jts, jte, kts, kte             )
    END IF

    END SUBROUTINE calculate_km_kh



SUBROUTINE cal_dampkm( config_flags,xkmh,xkhh,xkmv,xkhv,                       &
                       dx,dy,dt,dampcoef,                                      &
                       rdz, rdzw ,zdamp,                                       &
                       msftx, msfty,                                           &
                       ids,ide, jds,jde, kds,kde,                              &
                       ims,ime, jms,jme, kms,kme,                              &
                       its,ite, jts,jte, kts,kte                              )




   IMPLICIT NONE

   TYPE(grid_config_rec_type) , INTENT(IN   ) :: config_flags

   INTEGER ,          INTENT(IN   )           :: ids, ide, jds, jde, kds, kde, &
                                                 ims, ime, jms, jme, kms, kme, &
                                                 its, ite, jts, jte, kts, kte

   REAL    ,          INTENT(IN   )           :: zdamp,dx,dy,dt,dampcoef


   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT)    ::     xkmh , &
                                                                         xkhh , &
                                                                         xkmv , &
                                                                         xkhv 

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   )    ::     rdz,   &
                                                                         rdzw

   REAL , DIMENSION( ims:ime, jms:jme), INTENT(IN   )             ::     msftx, &
                                                                         msfty


   INTEGER :: i_start, i_end, j_start, j_end, ktf, ktfm1, i, j, k
   REAL    :: kmmax,kmmvmax,degrad90,dz,tmp
   REAL    :: ds
   REAL ,     DIMENSION( its:ite )                                ::   deltaz
   REAL , DIMENSION( its:ite, kts:kte, jts:jte)                   ::   dampk,dampkv




   ktf = min(kte,kde-1)
   ktfm1 = ktf-1

   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)


   IF(config_flags%specified .OR. config_flags%nested)THEN
     i_start = MAX(i_start,ids+config_flags%spec_bdy_width-1)
     i_end   = MIN(i_end,ide-config_flags%spec_bdy_width)
     j_start = MAX(j_start,jds+config_flags%spec_bdy_width-1)
     j_end   = MIN(j_end,jde-config_flags%spec_bdy_width)
   ENDIF

   kmmax=dx*dx/dt
   degrad90=DEGRAD*90.
   DO j = j_start, j_end

      k=ktf
      DO i = i_start, i_end
         
         
         
         
         
         
         ds = MIN(dx/msftx(i,j),dy/msfty(i,j))
         kmmax=ds*ds/dt



         dz = 1./rdzw(i,k,j)
         deltaz(i) = 0.5*dz

         kmmvmax=dz*dz/dt
         tmp=min(deltaz(i)/zdamp,1.)
         dampk(i,k,j)=cos(degrad90*tmp)*cos(degrad90*tmp)*kmmax*dampcoef
         dampkv(i,k,j)=cos(degrad90*tmp)*cos(degrad90*tmp)*kmmvmax*dampcoef

         dampkv(i,k,j)=min(dampkv(i,k,j),dampk(i,k,j))

      ENDDO

      DO k = ktfm1,kts,-1
      DO i = i_start, i_end
         
         
         
         
         
         
         ds = MIN(dx/msftx(i,j),dy/msfty(i,j))
         kmmax=ds*ds/dt



         dz = 1./rdz(i,k,j)
         deltaz(i) = deltaz(i) + dz
         dz = 1./rdzw(i,k,j)

         kmmvmax=dz*dz/dt
         tmp=min(deltaz(i)/zdamp,1.)
         dampk(i,k,j)=cos(degrad90*tmp)*cos(degrad90*tmp)*kmmax*dampcoef
         dampkv(i,k,j)=cos(degrad90*tmp)*cos(degrad90*tmp)*kmmvmax*dampcoef

         dampkv(i,k,j)=min(dampkv(i,k,j),dampk(i,k,j))
      ENDDO
      ENDDO

   ENDDO

   DO j = j_start, j_end
   DO k = kts,ktf
   DO i = i_start, i_end
      xkmh(i,k,j)=max(xkmh(i,k,j),dampk(i,k,j))
      xkhh(i,k,j)=max(xkhh(i,k,j),dampk(i,k,j))
      xkmv(i,k,j)=max(xkmv(i,k,j),dampkv(i,k,j))
      xkhv(i,k,j)=max(xkhv(i,k,j),dampkv(i,k,j))
   ENDDO
   ENDDO
   ENDDO

END SUBROUTINE cal_dampkm




    SUBROUTINE calculate_N2( config_flags, BN2, moist,           &
                             theta, t, p, p8w, t8w,              &
                             dnw, dn, rdz, rdzw,                 &
                             n_moist, cf1, cf2, cf3, warm_rain,  &
                             ids, ide, jds, jde, kds, kde,       &
                             ims, ime, jms, jme, kms, kme,       &
                             its, ite, jts, jte, kts, kte        )




    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: n_moist,  &
       ids, ide, jds, jde, kds, kde, &
       ims, ime, jms, jme, kms, kme, &
       its, ite, jts, jte, kts, kte

    LOGICAL, INTENT( IN )  &
    :: warm_rain

    REAL, INTENT( IN )  &
    :: cf1, cf2, cf3

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: BN2

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: rdz, rdzw, theta, t, p, p8w, t8w 

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: dnw, dn

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme, n_moist), INTENT( INOUT )  &
    :: moist



    INTEGER  &
    :: i, j, k, ktf, ispe, ktes1, ktes2,  &
       i_start, i_end, j_start, j_end

    REAL  &
    :: coefa, thetaep1, thetaem1, qc_cr, es, tc, qlpqi, qsw, qsi,  &
       tmpdz, xlvqv, thetaesfc, thetasfc, qvtop, qvsfc, thetatop, thetaetop

    REAL, DIMENSION( its:ite, jts:jte )  &
    :: tmp1sfc, tmp1top

    REAL, DIMENSION( its:ite, kts:kte, jts:jte )  &
    :: tmp1, qvs, qctmp




    qc_cr   = 0.00001  

    ktf     = MIN( kte, kde-1 )
    ktes1   = kte-1
    ktes2   = kte-2

    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested) i_end   = MIN( ide-2, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-2 ,jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )
 
    IF ( P_QC .GT. PARAM_FIRST_SCALAR) THEN
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
        qctmp(i,k,j) = moist(i,k,j,P_QC)
      END DO
      END DO
      END DO
    ELSE
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
         qctmp(i,k,j) = 0.0
      END DO
      END DO
      END DO
    END IF
 
    DO j = jts, jte
    DO k = kts, kte
    DO i = its, ite
      tmp1(i,k,j) = 0.0
    END DO
    END DO
    END DO
 
    DO j = jts,jte
    DO i = its,ite
      tmp1sfc(i,j) = 0.0
      tmp1top(i,j) = 0.0
    END DO
    END DO
 
    DO ispe = PARAM_FIRST_SCALAR, n_moist
      IF ( ispe .EQ. P_QV .OR. ispe .EQ. P_QC .OR. ispe .EQ. P_QI) THEN
        DO j = j_start, j_end
        DO k = kts, ktf
        DO i = i_start, i_end
          tmp1(i,k,j) = tmp1(i,k,j) + moist(i,k,j,ispe)
        END DO
        END DO
        END DO
 
        DO j = j_start, j_end
        DO i = i_start, i_end
          tmp1sfc(i,j) = tmp1sfc(i,j) +  &
                         cf1 * moist(i,1,j,ispe) +  &
                         cf2 * moist(i,2,j,ispe) +  &
                         cf3 * moist(i,3,j,ispe)
          tmp1top(i,j) = tmp1top(i,j) +  &
                         moist(i,ktes1,j,ispe) + &
                         ( moist(i,ktes1,j,ispe) - moist(i,ktes2,j,ispe) ) *  &
                         0.5 * dnw(ktes1) / dn(ktes1)
        END DO
        END DO
      END IF
    END DO



    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tc         = t(i,k,j) - SVPT0
      es         = 1000.0 * SVP1 * EXP( SVP2 * tc / ( t(i,k,j) - SVP3 ) )
      qvs(i,k,j) = EP_2 * es / ( p(i,k,j) - es )
    END DO
    END DO
    END DO
 
    DO j = j_start, j_end
    DO k = kts+1, ktf-1
    DO i = i_start, i_end
      tmpdz = 1.0 / rdz(i,k,j) + 1.0 / rdz(i,k+1,j)
      IF ( moist(i,k,j,P_QV) .GE. qvs(i,k,j) .OR. qctmp(i,k,j) .GE. qc_cr) THEN
        xlvqv      = XLV * moist(i,k,j,P_QV)
        coefa      = ( 1.0 + xlvqv / R_d / t(i,k,j) ) / &
                     ( 1.0 + XLV * xlvqv / Cp / R_v / t(i,k,j) / t(i,k,j) ) /  &
                     theta(i,k,j)
        thetaep1   = theta(i,k+1,j) *  &
                     ( 1.0 + XLV * qvs(i,k+1,j) / Cp / t(i,k+1,j) )
        thetaem1   = theta(i,k-1,j) *  &
                     ( 1.0 + XLV * qvs(i,k-1,j) / Cp / t(i,k-1,j) )
        BN2(i,k,j) = g * ( coefa * ( thetaep1 - thetaem1 ) / tmpdz -  &
                     ( tmp1(i,k+1,j) - tmp1(i,k-1,j) ) / tmpdz )
      ELSE
        BN2(i,k,j) = g * ( (theta(i,k+1,j) - theta(i,k-1,j) ) /  &
                     theta(i,k,j) / tmpdz +  &
                     1.61 * ( moist(i,k+1,j,P_QV) - moist(i,k-1,j,P_QV) ) / &
                     tmpdz -   &
                     ( tmp1(i,k+1,j) - tmp1(i,k-1,j) ) / tmpdz )
      ENDIF
    END DO
    END DO
    END DO

    k = kts
    DO j = j_start, j_end
    DO i = i_start, i_end
      tmpdz     = 1.0 / rdz(i,k+1,j) + 0.5 / rdzw(i,k,j)
      thetasfc  = T8w(i,kts,j) / ( p8w(i,k,j) / p1000mb )**( R_d / Cp )
      IF ( moist(i,k,j,P_QV) .GE. qvs(i,k,j) .OR. qctmp(i,k,j) .GE. qc_cr) THEN
        qvsfc     = cf1 * qvs(i,1,j) +  &
                    cf2 * qvs(i,2,j) +  &
                    cf3 * qvs(i,3,j)
        xlvqv      = XLV * moist(i,k,j,P_QV)
        coefa      = ( 1.0 + xlvqv / R_d / t(i,k,j) ) /  &
                     ( 1.0 + XLV * xlvqv / Cp / R_v / t(i,k,j) / t(i,k,j) ) /  &
                     theta(i,k,j)
        thetaep1   = theta(i,k+1,j) *  &
                     ( 1.0 + XLV * qvs(i,k+1,j) / Cp / t(i,k+1,j) )
        thetaesfc  = thetasfc *  &
                     ( 1.0 + XLV * qvsfc / Cp / t8w(i,kts,j) )
        BN2(i,k,j) = g * ( coefa * ( thetaep1 - thetaesfc ) / tmpdz -  &
                     ( tmp1(i,k+1,j) - tmp1sfc(i,j) ) / tmpdz )
      ELSE
        qvsfc     = cf1 * moist(i,1,j,P_QV) +  &
                    cf2 * moist(i,2,j,P_QV) +  &
                    cf3 * moist(i,3,j,P_QV)







        tmpdz= 1./rdzw(i,k,j) 
        BN2(i,k,j) = g * ( ( theta(i,k+1,j) - theta(i,k,j)) /  &
                     theta(i,k,j) / tmpdz +  &
                     1.61 * ( moist(i,k+1,j,P_QV) - qvsfc ) /  &
                     tmpdz -  &
                     ( tmp1(i,k+1,j) - tmp1sfc(i,j) ) / tmpdz  )


      ENDIF
    END DO
    END DO
 


    DO j = j_start, j_end
    DO i = i_start, i_end
       BN2(i,ktf,j)=BN2(i,ktf-1,j)
    END DO
    END DO   


    END SUBROUTINE calculate_N2




SUBROUTINE isotropic_km( config_flags,                                         &
                         xkmh,xkmv,xkhh,xkhv,khdif,kvdif,                      &
                         ids,ide, jds,jde, kds,kde,                            &
                         ims,ime, jms,jme, kms,kme,                            &
                         its,ite, jts,jte, kts,kte                            )




   IMPLICIT NONE

   TYPE(grid_config_rec_type) , INTENT(IN   ) :: config_flags

   INTEGER ,          INTENT(IN   )           :: ids, ide, jds, jde, kds, kde, &
                                                 ims, ime, jms, jme, kms, kme, &
                                                 its, ite, jts, jte, kts, kte

   REAL    ,          INTENT(IN   )           :: khdif,kvdif               

   REAL, DIMENSION( ims:ime , kms:kme , jms:jme ) , INTENT(INOUT) ::     xkmh, &
                                                                         xkmv, &
                                                                         xkhh, &
                                                                         xkhv


   INTEGER :: i_start, i_end, j_start, j_end, ktf, i, j, k
   REAL    :: khdif3,kvdif3




   ktf = kte

   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)



   khdif3=khdif/prandtl
   kvdif3=kvdif/prandtl

   DO j = j_start, j_end
   DO k = kts, ktf
   DO i = i_start, i_end
      xkmh(i,k,j)=khdif
      xkmv(i,k,j)=kvdif
      xkhh(i,k,j)=khdif3
      xkhv(i,k,j)=kvdif3
   ENDDO
   ENDDO
   ENDDO

END SUBROUTINE isotropic_km




SUBROUTINE smag_km( config_flags,xkmh,xkmv,xkhh,xkhv,BN2,                      &
                    div,defor11,defor22,defor33,defor12,                       &
                    defor13,defor23,                                           &
                    rdzw,dx,dy,dt,isotropic,                                   &
                    mix_upper_bound, msftx, msfty,                             &
                    ids,ide, jds,jde, kds,kde,                                 &
                    ims,ime, jms,jme, kms,kme,                                 &
                    its,ite, jts,jte, kts,kte                                  )




   IMPLICIT NONE

   TYPE(grid_config_rec_type) , INTENT(IN   ) :: config_flags

   INTEGER ,          INTENT(IN   )           :: ids, ide, jds, jde, kds, kde, &
                                                 ims, ime, jms, jme, kms, kme, &
                                                 its, ite, jts, jte, kts, kte

   INTEGER ,          INTENT(IN   )           :: isotropic
   REAL    ,          INTENT(IN   )           :: dx, dy, dt, mix_upper_bound


   REAL, DIMENSION( ims:ime , kms:kme , jms:jme ) , INTENT(IN   ) ::      BN2, &
                                                                         rdzw

   REAL, DIMENSION( ims:ime , kms:kme , jms:jme ) , INTENT(INOUT) ::     xkmh, &
                                                                         xkmv, &
                                                                         xkhh, &
                                                                         xkhv

   REAL , DIMENSION( ims:ime , kms:kme, jms:jme ),  INTENT(IN   )      ::      &    
                                                                      defor11, &
                                                                      defor22, &
                                                                      defor33, &
                                                                      defor12, &
                                                                      defor13, &
                                                                      defor23, &
                                                                          div
   REAL , DIMENSION( ims:ime, jms:jme), INTENT(IN   ) ::                msftx, &
                                                                        msfty


   INTEGER :: i_start, i_end, j_start, j_end, ktf, i, j, k
   REAL    :: deltas, tmp, pr, mlen_h, mlen_v, c_s

   REAL, DIMENSION( its:ite , kts:kte , jts:jte )                 ::     def2




   ktf = min(kte,kde-1)

   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )

   pr = prandtl
   c_s = config_flags%c_s

   do j=j_start,j_end
   do k=kts,ktf
   do i=i_start,i_end
      def2(i,k,j)=0.5*(defor11(i,k,j)*defor11(i,k,j) + &
                       defor22(i,k,j)*defor22(i,k,j) + &
                       defor33(i,k,j)*defor33(i,k,j))
   enddo
   enddo
   enddo

   do j=j_start,j_end
   do k=kts,ktf
   do i=i_start,i_end
      tmp=0.25*(defor12(i  ,k,j)+defor12(i  ,k,j+1)+ &
                defor12(i+1,k,j)+defor12(i+1,k,j+1))
      def2(i,k,j)=def2(i,k,j)+tmp*tmp
   enddo
   enddo
   enddo

   do j=j_start,j_end
   do k=kts,ktf
   do i=i_start,i_end
      tmp=0.25*(defor13(i  ,k+1,j)+defor13(i  ,k,j)+ &
                defor13(i+1,k+1,j)+defor13(i+1,k,j))
      def2(i,k,j)=def2(i,k,j)+tmp*tmp
   enddo
   enddo
   enddo

   do j=j_start,j_end
   do k=kts,ktf
   do i=i_start,i_end
      tmp=0.25*(defor23(i,k+1,j  )+defor23(i,k,j  )+ &
                defor23(i,k+1,j+1)+defor23(i,k,j+1))
      def2(i,k,j)=def2(i,k,j)+tmp*tmp
   enddo
   enddo
   enddo

   IF (isotropic .EQ. 0) THEN
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
         mlen_h=sqrt(dx/msftx(i,j) * dy/msfty(i,j))
         mlen_v= 1./rdzw(i,k,j)
         tmp=max(0.,def2(i,k,j)-BN2(i,k,j)/pr)
         tmp=tmp**0.5
         xkmh(i,k,j)=max(c_s*c_s*mlen_h*mlen_h*tmp, 1.0E-6*mlen_h*mlen_h )
         xkmh(i,k,j)=min(xkmh(i,k,j), mix_upper_bound * mlen_h * mlen_h / dt )
         xkmv(i,k,j)=max(c_s*c_s*mlen_v*mlen_v*tmp, 1.0E-6*mlen_v*mlen_v )
         xkmv(i,k,j)=min(xkmv(i,k,j), mix_upper_bound * mlen_v * mlen_v / dt )
         xkhh(i,k,j)=xkmh(i,k,j)/pr
         xkhh(i,k,j)=min(xkhh(i,k,j), mix_upper_bound * mlen_h * mlen_h / dt )
         xkhv(i,k,j)=xkmv(i,k,j)/pr
         xkhv(i,k,j)=min(xkhv(i,k,j), mix_upper_bound * mlen_v * mlen_v / dt )
      ENDDO
      ENDDO
      ENDDO
   ELSE
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
         deltas=(dx/msftx(i,j) * dy/msfty(i,j)/rdzw(i,k,j))**0.33333333
         tmp=max(0.,def2(i,k,j)-BN2(i,k,j)/pr)
         tmp=tmp**0.5
         xkmh(i,k,j)=max(c_s*c_s*deltas*deltas*tmp, 1.0E-6*deltas*deltas )
         xkmh(i,k,j)=min(xkmh(i,k,j), mix_upper_bound * dx/msftx(i,j) * dy/msfty(i,j) / dt )
         xkmv(i,k,j)=xkmh(i,k,j)
         xkmv(i,k,j)=min(xkmv(i,k,j), mix_upper_bound / rdzw(i,k,j) / rdzw(i,k,j) / dt )
         xkhh(i,k,j)=xkmh(i,k,j)/pr
         xkhh(i,k,j)=min(xkhh(i,k,j), mix_upper_bound * dx/msftx(i,j) * dy/msfty(i,j) / dt )
         xkhv(i,k,j)=xkmv(i,k,j)/pr
         xkhv(i,k,j)=min(xkhv(i,k,j), mix_upper_bound / rdzw(i,k,j) / rdzw(i,k,j) / dt )
      ENDDO
      ENDDO
      ENDDO
   ENDIF

END SUBROUTINE smag_km




SUBROUTINE smag2d_km( config_flags,xkmh,xkmv,xkhh,xkhv,                        &
                    defor11,defor22,defor12,                                   &
                    rdzw,dx,dy,msftx, msfty,zx,zy,                             &
                    ids,ide, jds,jde, kds,kde,                                 &
                    ims,ime, jms,jme, kms,kme,                                 &
                    its,ite, jts,jte, kts,kte                                  )




   IMPLICIT NONE

   TYPE(grid_config_rec_type) , INTENT(IN   ) :: config_flags

   INTEGER ,          INTENT(IN   )           :: ids, ide, jds, jde, kds, kde, &
                                                 ims, ime, jms, jme, kms, kme, &
                                                 its, ite, jts, jte, kts, kte

   REAL    ,          INTENT(IN   )           :: dx, dy


   REAL, DIMENSION( ims:ime , kms:kme , jms:jme ) , INTENT(IN   ) ::     rdzw,zx,zy

   REAL, DIMENSION( ims:ime , kms:kme , jms:jme ) , INTENT(INOUT) ::     xkmh, &
                                                                         xkmv, &
                                                                         xkhh, &
                                                                         xkhv

   REAL , DIMENSION( ims:ime , kms:kme, jms:jme ),  INTENT(IN   )      ::      &    
                                                                      defor11, &
                                                                      defor22, &
                                                                      defor12

   REAL , DIMENSION( ims:ime, jms:jme), INTENT(IN   ) ::                msftx, &
                                                                        msfty


   INTEGER :: i_start, i_end, j_start, j_end, ktf, i, j, k
   REAL    :: deltas, tmp, pr, mlen_h, c_s
   REAL    :: dxm, dym, tmpzx, tmpzy, alpha, def_limit

   REAL, DIMENSION( its:ite , kts:kte , jts:jte )                 ::     def2




   ktf = min(kte,kde-1)

   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )

   pr=prandtl
   c_s = config_flags%c_s

   do j=j_start,j_end
   do k=kts,ktf
   do i=i_start,i_end
      def2(i,k,j)=0.25*((defor11(i,k,j)-defor22(i,k,j))*(defor11(i,k,j)-defor22(i,k,j)))
      tmp=0.25*(defor12(i  ,k,j)+defor12(i  ,k,j+1)+ &
                defor12(i+1,k,j)+defor12(i+1,k,j+1))
      def2(i,k,j)=def2(i,k,j)+tmp*tmp
   enddo
   enddo
   enddo

      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
         mlen_h=sqrt(dx/msftx(i,j) * dy/msfty(i,j))
         tmp=sqrt(def2(i,k,j))

         xkmh(i,k,j)=c_s*c_s*mlen_h*mlen_h*tmp
         xkmh(i,k,j)=min(xkmh(i,k,j), 10.*mlen_h )
         xkmv(i,k,j)=0.
         xkhh(i,k,j)=xkmh(i,k,j)/pr
         xkhv(i,k,j)=0.
         IF(config_flags%diff_opt .EQ. 2)THEN

            dxm=dx/msftx(i,j)
            dym=dy/msfty(i,j)
            tmpzx = (0.25*( abs(zx(i,k,j))+ abs(zx(i+1,k,j  )) + abs(zx(i,k+1,j))+ abs(zx(i+1,k+1,j  )))*rdzw(i,k,j)*dxm)
            tmpzy = (0.25*( abs(zy(i,k,j))+ abs(zy(i  ,k,j+1)) + abs(zy(i,k+1,j))+ abs(zy(i  ,k+1,j+1)))*rdzw(i,k,j)*dym)
            alpha = max(sqrt(tmpzx*tmpzx+tmpzy*tmpzy),1.0)

            def_limit = max(10./mlen_h,1.e-3)
           if ( tmp .gt. def_limit ) then
             xkmh(i,k,j)=xkmh(i,k,j)/(alpha*alpha)
           else
             xkmh(i,k,j)=xkmh(i,k,j)/(alpha)
           endif
           xkhh(i,k,j)=xkmh(i,k,j)/pr
         ENDIF
      ENDDO
      ENDDO
      ENDDO

END SUBROUTINE smag2d_km




    SUBROUTINE tke_km( config_flags, xkmh, xkmv, xkhh, xkhv,         &
                       bn2, tke, p8w, t8w, theta,                    &
                       rdz, rdzw, dx,dy, dt, isotropic,              &
                       mix_upper_bound, msftx, msfty,                &
                       ids, ide, jds, jde, kds, kde,                 &
                       ims, ime, jms, jme, kms, kme,                 &
                       its, ite, jts, jte, kts, kte                  )














    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    INTEGER, INTENT( IN )  :: isotropic
    REAL, INTENT( IN )  &
    :: dx, dy, dt

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: tke, p8w, t8w, theta, rdz, rdzw, bn2

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: xkmh, xkmv, xkhh, xkhv

    REAL, INTENT( IN )  &
    :: mix_upper_bound

   REAL , DIMENSION( ims:ime, jms:jme), INTENT(IN   ) ::     msftx, &
                                                             msfty


    REAL, DIMENSION( its:ite, kts:kte, jts:jte )  &
    :: l_scale

    REAL, DIMENSION( its:ite, kts:kte, jts:jte )  &
    :: dthrdn

    REAL  &
    :: deltas, tmp, mlen_s, mlen_h, mlen_v, tmpdz,  &
       thetasfc, thetatop, minkx, pr_inv, pr_inv_h, pr_inv_v, c_k

    INTEGER  &
    :: i_start, i_end, j_start, j_end, ktf, i, j, k

    REAL, PARAMETER :: tke_seed_value = 1.e-06
    REAL            :: tke_seed
    REAL, PARAMETER :: epsilon = 1.e-10




    ktf     = MIN( kte, kde-1 )
    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested) i_end   = MIN( ide-2, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-2, jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )





    c_k = config_flags%c_k
    tke_seed = tke_seed_value
    if( (config_flags%tke_drag_coefficient .gt. epsilon) .or.  &
        (config_flags%tke_heat_flux .gt. epsilon)  ) tke_seed = 0.

    DO j = j_start, j_end
    DO k = kts+1, ktf-1
    DO i = i_start, i_end
      tmpdz         = 1.0 / rdz(i,k+1,j) + 1.0 / rdz(i,k,j) 
      dthrdn(i,k,j) = ( theta(i,k+1,j) - theta(i,k-1,j) ) / tmpdz
    END DO
    END DO
    END DO

    k = kts
    DO j = j_start, j_end
    DO i = i_start, i_end
      tmpdz         = 1.0 / rdzw(i,k+1,j) + 1.0 / rdzw(i,k,j) 
      thetasfc      = T8w(i,kts,j) / ( p8w(i,k,j) / p1000mb )**( R_d / Cp )
      dthrdn(i,k,j) = ( theta(i,k+1,j) - thetasfc ) / tmpdz
    END DO
    END DO

    k = ktf
    DO j = j_start, j_end
    DO i = i_start, i_end
      tmpdz         = 1.0 / rdz(i,k,j) + 0.5 / rdzw(i,k,j)
      thetatop      = T8w(i,kde,j) / ( p8w(i,kde,j) / p1000mb )**( R_d / Cp )
      dthrdn(i,k,j) = ( thetatop - theta(i,k-1,j) ) / tmpdz
    END DO
    END DO

    IF ( isotropic .EQ. 0 ) THEN
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
        mlen_h = SQRT( dx/msftx(i,j) * dy/msfty(i,j) )
        tmp    = SQRT( MAX( tke(i,k,j), tke_seed ) )
        deltas = 1.0 / rdzw(i,k,j)
        mlen_v = deltas
        IF ( dthrdn(i,k,j) .GT. 0.) THEN
          mlen_s = 0.76 * tmp / ( ABS( g / theta(i,k,j) * dthrdn(i,k,j) ) )**0.5
          mlen_v = MIN( mlen_v, mlen_s )
        END IF
        xkmh(i,k,j)  = MAX( c_k * tmp * mlen_h, 1.0E-6 * mlen_h * mlen_h )
        xkmh(i,k,j)  = MIN( xkmh(i,k,j), mix_upper_bound * mlen_h *mlen_h / dt )
        xkmv(i,k,j)  = MAX( c_k * tmp * mlen_v, 1.0E-6 * deltas * deltas )
        xkmv(i,k,j)  = MIN( xkmv(i,k,j), mix_upper_bound * deltas *deltas / dt )
        pr_inv_h     = 1./prandtl
        pr_inv_v     = 1.0 + 2.0 * mlen_v / deltas
        xkhh(i,k,j)  = xkmh(i,k,j) * pr_inv_h
        xkhv(i,k,j)  = xkmv(i,k,j) * pr_inv_v
      END DO
      END DO
      END DO
    ELSE
      CALL calc_l_scale( config_flags, tke, BN2, l_scale,      &
                         i_start, i_end, ktf, j_start, j_end,  &
                         dx, dy, rdzw, msftx, msfty,           &
                         ids, ide, jds, jde, kds, kde,         &
                         ims, ime, jms, jme, kms, kme,         &
                         its, ite, jts, jte, kts, kte          )
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
        tmp          = SQRT( MAX( tke(i,k,j), tke_seed ) )
        deltas       = ( dx/msftx(i,j) * dy/msfty(i,j) / rdzw(i,k,j) )**0.33333333
        xkmh(i,k,j)  = c_k * tmp * l_scale(i,k,j)
        xkmh(i,k,j)  = MIN( mix_upper_bound * dx/msftx(i,j) * dy/msfty(i,j) / dt,  xkmh(i,k,j) )
        xkmv(i,k,j)  = c_k * tmp * l_scale(i,k,j)
        xkmv(i,k,j)  = MIN( mix_upper_bound / rdzw(i,k,j) / rdzw(i,k,j) / dt ,  xkmv(i,k,j) )
        pr_inv       = 1.0 + 2.0 * l_scale(i,k,j) / deltas
        xkhh(i,k,j)  = MIN( mix_upper_bound * dx/msftx(i,j) * dy/msfty(i,j) / dt, xkmh(i,k,j) * pr_inv )
        xkhv(i,k,j)  = MIN( mix_upper_bound / rdzw(i,k,j) / rdzw(i,k,j) / dt, xkmv(i,k,j) * pr_inv )
      END DO
      END DO
      END DO
    END IF

    END SUBROUTINE tke_km




    SUBROUTINE calc_l_scale( config_flags, tke, BN2, l_scale,      &
                             i_start, i_end, ktf, j_start, j_end,  &
                             dx, dy, rdzw, msftx, msfty,           &
                             ids, ide, jds, jde, kds, kde,         &
                             ims, ime, jms, jme, kms, kme,         &
                             its, ite, jts, jte, kts, kte          )









    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: i_start, i_end, ktf, j_start, j_end,  &
       ids, ide, jds, jde, kds, kde,         &
       ims, ime, jms, jme, kms, kme,         &
       its, ite, jts, jte, kts, kte

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: BN2, tke, rdzw

    REAL, INTENT( IN )  &
    :: dx, dy

    REAL, DIMENSION( its:ite, kts:kte, jts:jte ), INTENT( OUT )  &
    :: l_scale

    REAL , DIMENSION( ims:ime, jms:jme), INTENT(IN   ) ::     msftx, &
                                                              msfty


    INTEGER  &
    :: i, j, k

    REAL  &
    :: deltas, tmp




    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      deltas         = ( dx/msftx(i,j) * dy/msfty(i,j) / rdzw(i,k,j) )**0.33333333
      l_scale(i,k,j) = deltas

      IF ( BN2(i,k,j) .gt. 1.0e-6 ) THEN
        tmp            = SQRT( MAX( tke(i,k,j), 1.0e-6 ) )
        l_scale(i,k,j) = 0.76 * tmp / SQRT( BN2(i,k,j) )
        l_scale(i,k,j) = MIN( l_scale(i,k,j), deltas)
        l_scale(i,k,j) = MAX( l_scale(i,k,j), 0.001 * deltas )
      END IF

    END DO
    END DO
    END DO

    END SUBROUTINE calc_l_scale




SUBROUTINE horizontal_diffusion_2 ( rt_tendf, ru_tendf, rv_tendf, rw_tendf,    &
                                    tke_tendf,                                 &
                                    moist_tendf, n_moist,                      &
                                    chem_tendf, n_chem,                        &
                                    scalar_tendf, n_scalar,                    &
                                    tracer_tendf, n_tracer,                    &
                                    thp, theta, mu, tke, config_flags,         &
                                    defor11, defor22, defor12,                 &
                                    defor13, defor23,                          &
                                    nba_mij, n_nba_mij,                        & 
                                    div,                                       &
                                    moist, chem, scalar,tracer,                &
                                    msfux, msfuy, msfvx, msfvy,                &
                                    msftx, msfty, xkmh, xkhh,km_opt,           &
                                    rdx, rdy, rdz, rdzw, fnm, fnp,             &
                                    cf1, cf2, cf3, zx, zy, dn, dnw, rho,       &
                                    ids, ide, jds, jde, kds, kde,              &
                                    ims, ime, jms, jme, kms, kme,              &
                                    its, ite, jts, jte, kts, kte               )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) ::        ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   INTEGER ,        INTENT(IN   ) ::        n_moist,n_chem,n_scalar,n_tracer,km_opt

   REAL ,           INTENT(IN   ) ::        cf1, cf2, cf3

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    dnw
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    dn

   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   msfux, &
                                                                    msfuy, &
                                                                    msfvx, &
                                                                    msfvy, &
                                                                    msftx, &
                                                                    msfty, &
                                                                      mu

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::rt_tendf,&
                                                                 ru_tendf,&
                                                                 rv_tendf,&
                                                                 rw_tendf,&
                                                                tke_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_moist),                 &
          INTENT(INOUT) ::                                    moist_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_chem),                  &
          INTENT(INOUT) ::                                     chem_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_scalar),                &
          INTENT(INOUT) ::                                   scalar_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_tracer),                &
          INTENT(INOUT) ::                                   tracer_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_moist),                 &
          INTENT(IN   ) ::                                          moist

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_chem),                  &
          INTENT(IN   ) ::                                          chem 

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_scalar) ,               &
          INTENT(IN   ) ::                                         scalar 

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_tracer) ,               &
          INTENT(IN   ) ::                                         tracer 

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::defor11, &
                                                                 defor22, &
                                                                 defor12, &
                                                                 defor13, &
                                                                 defor23, &
                                                                     div, &
                                                                    xkmh, &
                                                                    xkhh, &
                                                                      zx, &
                                                                      zy, &
                                                                   theta, &
                                                                     thp, &
                                                                     tke, &
                                                                     rdz, &
                                                                    rdzw, &
                                                                     rho    


   REAL ,                                        INTENT(IN   ) ::    rdx, &
                                                                     rdy
   INTEGER, INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij), INTENT(INOUT) &   
   :: nba_mij


   
   INTEGER :: im, ic, is









    CALL horizontal_diffusion_u_2( ru_tendf, mu, config_flags,             &
                                   defor11, defor12, div,                  &
                                   nba_mij, n_nba_mij,                     & 
                                   tke(ims,kms,jms),                       &
                                   msfux, msfuy, xkmh, rdx, rdy, fnm, fnp, &
                                   dnw, zx, zy, rdzw, rho,                 &
                                   ids, ide, jds, jde, kds, kde,           &
                                   ims, ime, jms, jme, kms, kme,           &
                                   its, ite, jts, jte, kts, kte           )

    CALL horizontal_diffusion_v_2( rv_tendf, mu, config_flags,             &
                                   defor12, defor22, div,                  &
                                   nba_mij, n_nba_mij,                     & 
                                   tke(ims,kms,jms),                       &
                                   msfvx, msfvy, xkmh, rdx, rdy, fnm, fnp, &
                                   dnw, zx, zy, rdzw, rho,                 &
                                   ids, ide, jds, jde, kds, kde,           &
                                   ims, ime, jms, jme, kms, kme,           &
                                   its, ite, jts, jte, kts, kte           )

    CALL horizontal_diffusion_w_2( rw_tendf, mu, config_flags,             &
                                   defor13, defor23, div,                  &
                                   nba_mij, n_nba_mij,                     & 
                                   tke(ims,kms,jms),                       &
                                   msftx, msfty, xkmh, rdx, rdy, fnm, fnp, &
                                   dn, zx, zy, rdz, rho,                   &
                                   ids, ide, jds, jde, kds, kde,           &
                                   ims, ime, jms, jme, kms, kme,           &
                                   its, ite, jts, jte, kts, kte           )

    CALL horizontal_diffusion_s  ( rt_tendf, mu, config_flags, thp,        &
                                   msftx, msfty, msfux, msfuy,             &
                                   msfvx, msfvy, xkhh, rdx, rdy,           &
                                   fnm, fnp, cf1, cf2, cf3,                &
                                   zx, zy, rdz, rdzw, dnw, dn, rho,        &
                                   .false.,                                &
                                   ids, ide, jds, jde, kds, kde,           &
                                   ims, ime, jms, jme, kms, kme,           &
                                   its, ite, jts, jte, kts, kte           )

    IF (km_opt .eq. 2)                                                     &
    CALL horizontal_diffusion_s  ( tke_tendf(ims,kms,jms),                 &
                                   mu, config_flags,                       &
                                   tke(ims,kms,jms),                       &
                                   msftx, msfty, msfux, msfuy,             &
                                   msfvx, msfvy, xkhh, rdx, rdy,           &
                                   fnm, fnp, cf1, cf2, cf3,                &
                                   zx, zy, rdz, rdzw, dnw, dn, rho,        &
                                   .true.,                                 &
                                   ids, ide, jds, jde, kds, kde,           &
                                   ims, ime, jms, jme, kms, kme,           &
                                   its, ite, jts, jte, kts, kte           )

    IF (n_moist .ge. PARAM_FIRST_SCALAR) THEN 

      moist_loop: do im = PARAM_FIRST_SCALAR, n_moist

          CALL horizontal_diffusion_s( moist_tendf(ims,kms,jms,im),       &
                                       mu, config_flags,                  &
                                       moist(ims,kms,jms,im),             &
                                       msftx, msfty, msfux, msfuy,        &
                                       msfvx, msfvy, xkhh, rdx, rdy,      &
                                       fnm, fnp, cf1, cf2, cf3,           &
                                       zx, zy, rdz, rdzw, dnw, dn, rho,   &
                                       .false.,                           &
                                       ids, ide, jds, jde, kds, kde,      &
                                       ims, ime, jms, jme, kms, kme,      &
                                       its, ite, jts, jte, kts, kte      )

      ENDDO moist_loop

    ENDIF

    IF (n_chem .ge. PARAM_FIRST_SCALAR) THEN 

      chem_loop: do ic = PARAM_FIRST_SCALAR, n_chem

        CALL horizontal_diffusion_s( chem_tendf(ims,kms,jms,ic),     &
                                     mu, config_flags,                 &
                                     chem(ims,kms,jms,ic),           &
                                     msftx, msfty, msfux, msfuy,       &
                                     msfvx, msfvy, xkhh, rdx, rdy,     &
                                     fnm, fnp, cf1, cf2, cf3,          &
                                     zx, zy, rdz, rdzw, dnw, dn, rho,  &
                                     .false.,                          &
                                     ids, ide, jds, jde, kds, kde,     &
                                     ims, ime, jms, jme, kms, kme,     &
                                     its, ite, jts, jte, kts, kte     )

      ENDDO chem_loop

    ENDIF

    IF (n_tracer .ge. PARAM_FIRST_SCALAR) THEN 

      tracer_loop: do ic = PARAM_FIRST_SCALAR, n_tracer

        CALL horizontal_diffusion_s( tracer_tendf(ims,kms,jms,ic),     &
                                     mu, config_flags,                 &
                                     tracer(ims,kms,jms,ic),           &
                                     msftx, msfty, msfux, msfuy,       &
                                     msfvx, msfvy, xkhh, rdx, rdy,     &
                                     fnm, fnp, cf1, cf2, cf3,          &
                                     zx, zy, rdz, rdzw, dnw, dn, rho,  &
                                     .false.,                          &
                                     ids, ide, jds, jde, kds, kde,     &
                                     ims, ime, jms, jme, kms, kme,     &
                                     its, ite, jts, jte, kts, kte     )

      ENDDO tracer_loop

    ENDIF
    IF (n_scalar .ge. PARAM_FIRST_SCALAR) THEN 

      scalar_loop: do is = PARAM_FIRST_SCALAR, n_scalar

        CALL horizontal_diffusion_s( scalar_tendf(ims,kms,jms,is),     &
                                     mu, config_flags,                 &
                                     scalar(ims,kms,jms,is),           &
                                     msftx, msfty, msfux, msfuy,       &
                                     msfvx, msfvy, xkhh, rdx, rdy,     &
                                     fnm, fnp, cf1, cf2, cf3,          &
                                     zx, zy, rdz, rdzw, dnw, dn, rho,  &
                                     .false.,                          &
                                     ids, ide, jds, jde, kds, kde,     &
                                     ims, ime, jms, jme, kms, kme,     &
                                     its, ite, jts, jte, kts, kte     )

      ENDDO scalar_loop

    ENDIF

    END SUBROUTINE horizontal_diffusion_2




SUBROUTINE horizontal_diffusion_u_2( tendency, mu, config_flags,          &
                                     defor11, defor12, div,               &
                                     nba_mij, n_nba_mij,                  & 
                                     tke,                                 &
                                     msfux, msfuy,                        &
                                     xkmh, rdx, rdy, fnm, fnp,            &
                                     dnw, zx, zy, rdzw, rho,              &
                                     ids, ide, jds, jde, kds, kde,        &
                                     ims, ime, jms, jme, kms, kme,        &
                                     its, ite, jts, jte, kts, kte        )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) ::        ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    dnw

   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::  msfux, &
                                                                   msfuy, &
                                                                      mu

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::tendency

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::   rdzw, &  
                                                                     rho  
                                                                    
 
   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::defor11, &
                                                                 defor12, &
                                                                     div, &   
                                                                     tke, &   
                                                                    xkmh, &
                                                                      zx, &
                                                                      zy

   INTEGER, INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij),  INTENT(INOUT) &  
   :: nba_mij

   REAL ,                                        INTENT(IN   ) ::    rdx, &
                                                                     rdy

   
   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end
   INTEGER :: is_ext,ie_ext,js_ext,je_ext  

   REAL , DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1)    :: titau1avg, &
                                                              titau2avg, &
                                                                 titau1, & 
                                                                 titau2, & 
                                                                 xkxavg, & 
                                                                  rravg



   REAL :: mrdx, mrdy, rcoup

   REAL :: tmpzy, tmpzeta_z

   REAL :: tmpdz

   REAL :: term1, term2, term3




   ktf=MIN(kte,kde-1)
 


















   i_start = its
   i_end   = ite
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-1,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = ite


   is_ext=1
   ie_ext=0
   js_ext=0
   je_ext=0
   CALL cal_titau_11_22_33( config_flags, titau1,            &
                            mu, tke, xkmh, defor11,          &
                            nba_mij(ims,kms,jms,P_m11), rho, & 
                            is_ext, ie_ext, js_ext, je_ext,  &
                            ids, ide, jds, jde, kds, kde,    &
                            ims, ime, jms, jme, kms, kme,    &
                            its, ite, jts, jte, kts, kte     )


   is_ext=0
   ie_ext=0
   js_ext=0
   je_ext=1
   CALL cal_titau_12_21( config_flags, titau2,            &
                         mu, xkmh, defor12,               &
                         nba_mij(ims,kms,jms,P_m12), rho, & 
                         is_ext, ie_ext, js_ext, je_ext,  &
                         ids, ide, jds, jde, kds, kde,    &
                         ims, ime, jms, jme, kms, kme,    &
                         its, ite, jts, jte, kts, kte     )




   DO j = j_start, j_end
   DO k = kts+1,ktf
   DO i = i_start, i_end
      titau1avg(i,k,j)=0.5*(fnm(k)*(titau1(i-1,k  ,j)+titau1(i,k  ,j))+ &
                            fnp(k)*(titau1(i-1,k-1,j)+titau1(i,k-1,j)))
      titau2avg(i,k,j)=0.5*(fnm(k)*(titau2(i,k  ,j+1)+titau2(i,k  ,j))+ &
                            fnp(k)*(titau2(i,k-1,j+1)+titau2(i,k-1,j)))
      tmpzy = 0.25*( zy(i-1,k,j  )+zy(i,k,j  )+ &
                     zy(i-1,k,j+1)+zy(i,k,j+1)  )




      titau1avg(i,k,j)=titau1avg(i,k,j)*zx(i,k,j)
      titau2avg(i,k,j)=titau2avg(i,k,j)*tmpzy    

   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO i = i_start, i_end
      titau1avg(i,kts,j)=0.
      titau1avg(i,ktf+1,j)=0.
      titau2avg(i,kts,j)=0.
      titau2avg(i,ktf+1,j)=0.
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts,ktf
   DO i = i_start, i_end

      mrdx=msfux(i,j)*rdx
      mrdy=msfuy(i,j)*rdy








      tmpdz = (1./rdzw(i,k,j)+1./rdzw(i-1,k,j))/2.                      
      tendency(i,k,j)=tendency(i,k,j) +  g*tmpdz/dnw(k) *             & 
           (mrdx*(titau1(i,k,j  ) - titau1(i-1,k,j)) +                & 
            mrdy*(titau2(i,k,j+1) - titau2(i  ,k,j)) -                & 
            msfuy(i,j)*(titau1avg(i,k+1,j)-titau1avg(i,k,j))/tmpdz -  & 
            msfuy(i,j)*(titau2avg(i,k+1,j)-titau2avg(i,k,j))/tmpdz    & 
                                                                  )     

   ENDDO
   ENDDO
   ENDDO

END SUBROUTINE horizontal_diffusion_u_2




SUBROUTINE horizontal_diffusion_v_2( tendency, mu, config_flags,          &
                                     defor12, defor22, div,               &
                                     nba_mij, n_nba_mij,                  & 
                                     tke,                                 &
                                     msfvx, msfvy,                        &
                                     xkmh, rdx, rdy, fnm, fnp,            &
                                     dnw, zx, zy, rdzw, rho,              &
                                     ids, ide, jds, jde, kds, kde,        &
                                     ims, ime, jms, jme, kms, kme,        &
                                     its, ite, jts, jte, kts, kte        )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) ::        ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    dnw 

   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::  msfvx, &
                                                                   msfvy, &
                                                                      mu

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) :: tendency

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::defor12, &
                                                                 defor22, &
                                                                     div, &
                                                                     tke, &
                                                                    xkmh, &
                                                                      zx, &
                                                                      zy, &
                                                                    rdzw, &
                                                                     rho    

   INTEGER,  INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij),  INTENT(INOUT) &  
   :: nba_mij

   REAL ,                                        INTENT(IN   ) ::    rdx, &
                                                                     rdy



   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end
   INTEGER :: is_ext,ie_ext,js_ext,je_ext  

   REAL , DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1)    :: titau1avg, &
                                                              titau2avg, &
                                                                 titau1, &
                                                                 titau2, &
                                                                 xkxavg, &
                                                                  rravg




   REAL :: mrdx, mrdy, rcoup
   REAL :: tmpdz              
   REAL :: tmpzx, tmpzeta_z




   ktf=MIN(kte,kde-1)
 


















   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = jte

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-1,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN(ite,ide-1)


   is_ext=0
   ie_ext=1
   js_ext=0
   je_ext=0
   CALL cal_titau_12_21( config_flags, titau1,          &
                         mu, xkmh, defor12,             &
                         nba_mij(ims,kms,jms,P_m12),rho,& 
                         is_ext,ie_ext,js_ext,je_ext,   &
                         ids, ide, jds, jde, kds, kde,  &
                         ims, ime, jms, jme, kms, kme,  &
                         its, ite, jts, jte, kts, kte   )


   is_ext=0
   ie_ext=0
   js_ext=1
   je_ext=0
   CALL cal_titau_11_22_33( config_flags, titau2,           &
                            mu, tke, xkmh, defor22,         &
                            nba_mij(ims,kms,jms,P_m22),rho, & 
                            is_ext, ie_ext, js_ext, je_ext, &
                            ids, ide, jds, jde, kds, kde,   &
                            ims, ime, jms, jme, kms, kme,   &
                            its, ite, jts, jte, kts, kte    )

   DO j = j_start, j_end
   DO k = kts+1,ktf
   DO i = i_start, i_end
      titau1avg(i,k,j)=0.5*(fnm(k)*(titau1(i+1,k  ,j)+titau1(i,k  ,j))+ &
                            fnp(k)*(titau1(i+1,k-1,j)+titau1(i,k-1,j)))
      titau2avg(i,k,j)=0.5*(fnm(k)*(titau2(i,k  ,j-1)+titau2(i,k  ,j))+ &
                            fnp(k)*(titau2(i,k-1,j-1)+titau2(i,k-1,j)))

      tmpzx = 0.25*( zx(i,k,j  )+zx(i+1,k,j  )+ &
                     zx(i,k,j-1)+zx(i+1,k,j-1)  )


      titau1avg(i,k,j)=titau1avg(i,k,j)*tmpzx
      titau2avg(i,k,j)=titau2avg(i,k,j)*zy(i,k,j)


   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO i = i_start, i_end
      titau1avg(i,kts,j)=0.
      titau1avg(i,ktf+1,j)=0.
      titau2avg(i,kts,j)=0.
      titau2avg(i,ktf+1,j)=0.
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts,ktf
   DO i = i_start, i_end
       
      mrdx=msfvx(i,j)*rdx
      mrdy=msfvy(i,j)*rdy








      tmpdz = (1./rdzw(i,k,j)+1./rdzw(i,k,j-1))/2.                      
      tendency(i,k,j)=tendency(i,k,j) +    g*tmpdz/dnw(k) *           & 
           (mrdx*(titau2(i,k,j  ) - titau2(i,k,j-1)) +                & 
            mrdy*(titau1(i+1,k,j) - titau1(i  ,k,j)) -                & 
            msfvy(i,j)*(titau1avg(i,k+1,j)-titau1avg(i,k,j))/tmpdz -  & 
            msfvy(i,j)*(titau2avg(i,k+1,j)-titau2avg(i,k,j))/tmpdz    & 
                                                                  )     


   ENDDO
   ENDDO
   ENDDO

END SUBROUTINE horizontal_diffusion_v_2




SUBROUTINE horizontal_diffusion_w_2( tendency, mu, config_flags,          &
                                     defor13, defor23, div,               &
                                     nba_mij, n_nba_mij,                  & 
                                     tke,                                 &
                                     msftx, msfty,                        &
                                     xkmh, rdx, rdy, fnm, fnp,            &
                                     dn, zx, zy, rdz, rho,                &
                                     ids, ide, jds, jde, kds, kde,        &
                                     ims, ime, jms, jme, kms, kme,        &
                                     its, ite, jts, jte, kts, kte        )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) ::        ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    dn    

   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::  msftx, &
                                                                   msfty, &
                                                                      mu

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) :: tendency

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::defor13, &
                                                                 defor23, &
                                                                     div, &
                                                                     tke, &
                                                                    xkmh, &
                                                                      zx, &
                                                                      zy, &
                                                                     rdz, &
                                                                     rho     

   INTEGER,  INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij),  INTENT(INOUT) &   
   :: nba_mij

   REAL ,                                        INTENT(IN   ) ::    rdx, &
                                                                     rdy



   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end
   INTEGER :: is_ext,ie_ext,js_ext,je_ext  

   REAL , DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1)    :: titau1avg, &
                                                              titau2avg, &
                                                                 titau1, &
                                                                 titau2, &
                                                                 xkxavg, &
                                                                  rravg




   REAL :: mrdx, mrdy, rcoup

   REAL :: tmpzx, tmpzy, tmpzeta_z




   ktf=MIN(kte,kde-1)
 

















   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN(ite,ide-1)


   is_ext=0
   ie_ext=1
   js_ext=0
   je_ext=0
   CALL cal_titau_13_31( config_flags, titau1, defor13,   &
                         nba_mij(ims,kms,jms,P_m13),      & 
                         mu, xkmh, fnm, fnp, rho,         &
                         is_ext, ie_ext, js_ext, je_ext,  &
                         ids, ide, jds, jde, kds, kde,    &
                         ims, ime, jms, jme, kms, kme,    &
                         its, ite, jts, jte, kts, kte     )


   is_ext=0
   ie_ext=0
   js_ext=0
   je_ext=1
   CALL cal_titau_23_32( config_flags, titau2, defor23,   &
                         nba_mij(ims,kms,jms,P_m23),      & 
                         mu, xkmh, fnm, fnp, rho,         &
                         is_ext, ie_ext, js_ext, je_ext,  &
                         ids, ide, jds, jde, kds, kde,    &
                         ims, ime, jms, jme, kms, kme,    &
                         its, ite, jts, jte, kts, kte     )




   DO j = j_start, j_end
   DO k = kts,ktf
   DO i = i_start, i_end
      titau1avg(i,k,j)=0.25*(titau1(i+1,k+1,j)+titau1(i,k+1,j)+ &
                             titau1(i+1,k  ,j)+titau1(i,k  ,j))
      titau2avg(i,k,j)=0.25*(titau2(i,k+1,j+1)+titau2(i,k+1,j)+ &
                             titau2(i,k  ,j+1)+titau2(i,k  ,j))

      tmpzx  =0.25*( zx(i,k  ,j)+zx(i+1,k  ,j)+ &
                     zx(i,k+1,j)+zx(i+1,k+1,j)  )
      tmpzy  =0.25*( zy(i,k  ,j)+zy(i,k  ,j+1)+ &
                     zy(i,k+1,j)+zy(i,k+1,j+1)  )

      titau1avg(i,k,j)=titau1avg(i,k,j)*tmpzx
      titau2avg(i,k,j)=titau2avg(i,k,j)*tmpzy


   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO i = i_start, i_end
      titau1avg(i,ktf+1,j)=0.
      titau2avg(i,ktf+1,j)=0.
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts+1,ktf
   DO i = i_start, i_end

      mrdx=msftx(i,j)*rdx
      mrdy=msfty(i,j)*rdy









     tendency(i,k,j)=tendency(i,k,j) +   g/(dn(k)*rdz(i,k,j)) *         & 
           (mrdx*(titau1(i+1,k,j)-titau1(i,k,j))+                       & 
            mrdy*(titau2(i,k,j+1)-titau2(i,k,j))-                       & 
            msfty(i,j)*rdz(i,k,j)*(titau1avg(i,k,j)-titau1avg(i,k-1,j)+ & 
                                   titau2avg(i,k,j)-titau2avg(i,k-1,j)  & 
                                  )                                     & 
           )                                                              

   ENDDO
   ENDDO
   ENDDO

END SUBROUTINE horizontal_diffusion_w_2




SUBROUTINE horizontal_diffusion_s (tendency, mu, config_flags, var,       &
                                   msftx, msfty, msfux, msfuy,            &
                                   msfvx, msfvy, xkhh, rdx, rdy,          &
                                   fnm, fnp, cf1, cf2, cf3,               &
                                   zx, zy, rdz, rdzw, dnw, dn, rho,       &
                                   doing_tke,                             &
                                   ids, ide, jds, jde, kds, kde,          &
                                   ims, ime, jms, jme, kms, kme,          &
                                   its, ite, jts, jte, kts, kte           )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) ::        ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   LOGICAL,         INTENT(IN   ) ::        doing_tke

   REAL , INTENT(IN   )           ::        cf1, cf2, cf3

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::     dn
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    dnw

   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   msfux
   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   msfuy
   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   msfvx
   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   msfvy
   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   msftx
   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   msfty

   REAL , DIMENSION( ims:ime, jms:jme) ,         INTENT(IN   ) ::   mu




   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) :: tendency

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::         &
                                                                    xkhh, &
                                                                     rdz, &
                                                                    rdzw, &
                                                                     rho  

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::    var, &
                                                                      zx, &
                                                                      zy

   REAL ,                                        INTENT(IN   ) ::    rdx, &
                                                                     rdy



   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end

   REAL , DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1)    ::     H1avg, &
                                                                  H2avg, &
                                                                     H1, &
                                                                     H2, &
                                                                 xkxavg




   REAL , DIMENSION( its:ite, kts:kte, jts:jte)            ::  tmptendf

   REAL    :: mrdx, mrdy, rcoup
   REAL    :: tmpzx, tmpzy, tmpzeta_z, rdzu, rdzv
   INTEGER :: ktes1,ktes2




   ktf=MIN(kte,kde-1)
 


















   ktes1=kte-1
   ktes2=kte-2

   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN(ite,ide-1)



   IF ( doing_tke ) THEN
      DO j = j_start, j_end
      DO k = kts,ktf
      DO i = i_start, i_end
         tmptendf(i,k,j)=tendency(i,k,j)
      ENDDO
      ENDDO
      ENDDO
   ENDIF



   DO j = j_start, j_end
   DO k = kts, ktf
   DO i = i_start, i_end + 1


      xkxavg(i,k,j)=0.5*(xkhh(i-1,k,j)+xkhh(i,k,j))*0.5*(rho(i-1,k,j)+rho(i,k,j))
   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts+1, ktf
   DO i = i_start, i_end + 1
      H1avg(i,k,j)=0.5*(fnm(k)*(var(i-1,k  ,j)+var(i,k  ,j))+  &
                        fnp(k)*(var(i-1,k-1,j)+var(i,k-1,j)))
   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO i = i_start, i_end + 1
      H1avg(i,kts  ,j)=0.5*(cf1*var(i  ,1,j)+cf2*var(i  ,2,j)+ &
                            cf3*var(i  ,3,j)+cf1*var(i-1,1,j)+  &
                            cf2*var(i-1,2,j)+cf3*var(i-1,3,j))
      H1avg(i,ktf+1,j)=0.5*(var(i,ktes1,j)+(var(i,ktes1,j)- &
                            var(i,ktes2,j))*0.5*dnw(ktes1)/dn(ktes1)+ &
                            var(i-1,ktes1,j)+(var(i-1,ktes1,j)- &
                            var(i-1,ktes2,j))*0.5*dnw(ktes1)/dn(ktes1))
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts, ktf
   DO i = i_start, i_end + 1

      tmpzx = 0.5*( zx(i,k,j)+ zx(i,k+1,j))
      rdzu = 2./(1./rdzw(i,k,j) + 1./rdzw(i-1,k,j))
      H1(i,k,j)=-msfuy(i,j)*xkxavg(i,k,j)*(                      &
                 rdx*(var(i,k,j)-var(i-1,k,j)) - tmpzx*         &
                     (H1avg(i,k+1,j)-H1avg(i,k,j))*rdzu )





   ENDDO
   ENDDO
   ENDDO



   DO j = j_start, j_end + 1
   DO k = kts, ktf
   DO i = i_start, i_end



      xkxavg(i,k,j)=0.5*(xkhh(i,k,j-1)+xkhh(i,k,j))*0.5*(rho(i,k,j-1)+rho(i,k,j))
   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end + 1
   DO k = kts+1,   ktf
   DO i = i_start, i_end

      H2avg(i,k,j)=0.5*(fnm(k)*(var(i,k  ,j-1)+var(i,k  ,j))+  &
                        fnp(k)*(var(i,k-1,j-1)+var(i,k-1,j)))
   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end + 1
   DO i = i_start, i_end
      H2avg(i,kts  ,j)=0.5*(cf1*var(i,1,j  )+cf2*var(i  ,2,j)+ &
                            cf3*var(i,3,j  )+cf1*var(i,1,j-1)+  &
                            cf2*var(i,2,j-1)+cf3*var(i,3,j-1))
      H2avg(i,ktf+1,j)=0.5*(var(i,ktes1,j)+(var(i,ktes1,j)- &
                            var(i,ktes2,j))*0.5*dnw(ktes1)/dn(ktes1)+ &
                            var(i,ktes1,j-1)+(var(i,ktes1,j-1)- &
                            var(i,ktes2,j-1))*0.5*dnw(ktes1)/dn(ktes1))
   ENDDO
   ENDDO

   DO j = j_start, j_end + 1
   DO k = kts, ktf
   DO i = i_start, i_end

      tmpzy = 0.5*( zy(i,k,j)+ zy(i,k+1,j))
      rdzv = 2./(1./rdzw(i,k,j) + 1./rdzw(i,k,j-1))
      H2(i,k,j)=-msfvy(i,j)*xkxavg(i,k,j)*(                       &
                 rdy*(var(i,k,j)-var(i,k,j-1)) - tmpzy*          &
                     (H2avg(i ,k+1,j)-H2avg(i,k,j))*rdzv)





   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts+1, ktf
   DO i = i_start, i_end
      H1avg(i,k,j)=0.5*(fnm(k)*(H1(i+1,k  ,j)+H1(i,k  ,j))+  &
                        fnp(k)*(H1(i+1,k-1,j)+H1(i,k-1,j)))
      H2avg(i,k,j)=0.5*(fnm(k)*(H2(i,k  ,j+1)+H2(i,k  ,j))+  &
                        fnp(k)*(H2(i,k-1,j+1)+H2(i,k-1,j)))







      tmpzx = 0.5*( zx(i,k,j)+ zx(i+1,k,j  ))
      tmpzy = 0.5*( zy(i,k,j)+ zy(i  ,k,j+1))

      H1avg(i,k,j)=H1avg(i,k,j)*tmpzx
      H2avg(i,k,j)=H2avg(i,k,j)*tmpzy



   ENDDO
   ENDDO
   ENDDO
 
   DO j = j_start, j_end
   DO i = i_start, i_end
      H1avg(i,kts  ,j)=0.
      H1avg(i,ktf+1,j)=0.
      H2avg(i,kts  ,j)=0.
      H2avg(i,ktf+1,j)=0.
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts,ktf
   DO i = i_start, i_end

      mrdx=msftx(i,j)*rdx
      mrdy=msfty(i,j)*rdy











      tendency(i,k,j)=tendency(i,k,j) +   g/(dnw(k)*rdzw(i,k,j)) * &  
           (mrdx*(H1(i+1,k,j)-H1(i  ,k,j)) +                       &  
            mrdy*(H2(i,k,j+1)-H2(i,k,j  )) -                       &  
            msfty(i,j)*(H1avg(i,k+1,j)-H1avg(i,k,j))*rdzw(i,k,j) - &  
            msfty(i,j)*(H2avg(i,k+1,j)-H2avg(i,k,j))*rdzw(i,k,j)   &  
           )                                                          

   ENDDO
   ENDDO
   ENDDO
           
   IF ( doing_tke ) THEN
      DO j = j_start, j_end
      DO k = kts,ktf
      DO i = i_start, i_end
          tendency(i,k,j)=tmptendf(i,k,j)+2.* &
                          (tendency(i,k,j)-tmptendf(i,k,j))
      ENDDO
      ENDDO
      ENDDO
   ENDIF

END SUBROUTINE horizontal_diffusion_s




SUBROUTINE vertical_diffusion_2   ( ru_tendf, rv_tendf, rw_tendf, rt_tendf,   &
                                    tke_tendf, moist_tendf, n_moist,          &
                                    chem_tendf, n_chem,                       &
                                    scalar_tendf, n_scalar,                   &
                                    tracer_tendf, n_tracer,                   &
                                    u_2, v_2,                                 &
                                    thp,u_base,v_base,t_base,qv_base,mu,tke,  &
                                    config_flags,defor13,defor23,defor33,     &
                                    nba_mij, n_nba_mij,                       & 
                                    div,                                      &
                                    moist,chem,scalar,tracer,                 &
                                    xkmv,xkhv,xkmh,km_opt,                    & 
                                    fnm, fnp, dn, dnw, rdz, rdzw,             &
                                    hfx, qfx, ust, rho,                       &
                                    ids, ide, jds, jde, kds, kde,             &
                                    ims, ime, jms, jme, kms, kme,             &
                                    its, ite, jts, jte, kts, kte              )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) ::        ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   INTEGER ,        INTENT(IN   ) ::        n_moist,n_chem,n_scalar,n_tracer,km_opt

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) :: fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) :: fnp
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) :: dnw
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::  dn
   REAL , DIMENSION( ims:ime , jms:jme ) ,  INTENT(IN   )      ::  mu

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) :: qv_base
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::  u_base
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::  v_base
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::  t_base

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::ru_tendf,&
                                                                 rv_tendf,&
                                                                 rw_tendf,&
                                                                tke_tendf,&
                                                                rt_tendf  

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_moist),                 &
          INTENT(INOUT) ::                                    moist_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_chem),                  &
          INTENT(INOUT) ::                                     chem_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_scalar) ,               &
          INTENT(INOUT) ::                                   scalar_tendf
   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_tracer) ,               &
          INTENT(INOUT) ::                                   tracer_tendf

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_moist),                 &
          INTENT(INOUT) ::                                          moist

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_chem),                  &
          INTENT(INOUT) ::                                           chem

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_scalar) ,               &
          INTENT(IN   ) ::                                         scalar
   REAL , DIMENSION( ims:ime, kms:kme, jms:jme, n_tracer) ,               &
          INTENT(IN   ) ::                                         tracer

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   ) ::defor13, &
                                                                 defor23, &
                                                                 defor33, &
                                                                     div, &
                                                                    xkmv, &
                                                                    xkhv, &
                                                                    xkmh, &
                                                                     tke, &
                                                                     rdz, &
                                                                     u_2, &
                                                                     v_2, &
                                                                    rdzw

   INTEGER, INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij), INTENT(INOUT) &  
   :: nba_mij

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(IN   )   :: rho  
   REAL , DIMENSION( ims:ime, jms:jme), INTENT(INOUT)            :: hfx,  &
                                                                    qfx
   REAL , DIMENSION( ims:ime, jms:jme), INTENT(IN   )            :: ust
   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::    thp



   REAL , DIMENSION( ims:ime, kms:kme, jms:jme)  ::    var_mix

   INTEGER :: im, i,j,k
   INTEGER :: i_start, i_end, j_start, j_end







    REAL :: V0_u,V0_v,tao_xz,tao_yz,ustar,cd0
    REAL :: xsfc,psi1,vk2,zrough,lnz
    REAL :: heat_flux, moist_flux, heat_flux0
    REAL :: cpm








   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)



      CALL vertical_diffusion_u_2( ru_tendf, config_flags, mu,    &
                                   defor13, xkmv,                 &
                                   nba_mij, n_nba_mij,            & 
                                   dnw, rdzw, fnm, fnp, rho,      &
                                   ids, ide, jds, jde, kds, kde,  &
                                   ims, ime, jms, jme, kms, kme,  &
                                   its, ite, jts, jte, kts, kte  )


      CALL vertical_diffusion_v_2( rv_tendf, config_flags, mu,    &
                                   defor23, xkmv,                 &
                                   nba_mij, n_nba_mij,            & 
                                   dnw, rdzw, fnm, fnp, rho,      &
                                   ids, ide, jds, jde, kds, kde,  &
                                   ims, ime, jms, jme, kms, kme,  &
                                   its, ite, jts, jte, kts, kte  )

      CALL vertical_diffusion_w_2( rw_tendf, config_flags, mu,    &
                                   defor33, tke(ims,kms,jms),     &
                                   nba_mij, n_nba_mij,            & 
                                   div, xkmh,                     & 
                                   dn, rdz, fnm, fnp, rho,        &
                                   ids, ide, jds, jde, kds, kde,  &
                                   ims, ime, jms, jme, kms, kme,  &
                                   its, ite, jts, jte, kts, kte  )





  vflux: SELECT CASE( config_flags%isfflx )
  CASE (0) 
    cd0 = config_flags%tke_drag_coefficient  
                                             


    DO j = j_start, j_end
    DO i = i_start, ite
       V0_u=0.
       tao_xz=0.
       V0_u=    sqrt((u_2(i,kts,j)**2) +         &
                        (((v_2(i  ,kts,j  )+          &
                           v_2(i  ,kts,j+1)+          &
                           v_2(i-1,kts,j  )+          &
                           v_2(i-1,kts,j+1))/4)**2))+epsilon





       tao_xz=cd0*V0_u*u_2(i,kts,j)*(rho(i,kts,j)+rho(i-1,kts,j))/2.                        
       ru_tendf(i,kts,j)=ru_tendf(i,kts,j) +   g*tao_xz/dnw(kts)                            

       IF ( (config_flags%m_opt .EQ. 1) .OR. (config_flags%sfs_opt .GT. 0) ) THEN
          nba_mij(i,kts,j,P_m13) = -tao_xz
       ENDIF   
    ENDDO
    ENDDO

    DO j = j_start, jte
    DO i = i_start, i_end
       V0_v=0.
       tao_yz=0.
       V0_v=    sqrt((v_2(i,kts,j)**2) +         &
                        (((u_2(i  ,kts,j  )+          &
                           u_2(i  ,kts,j-1)+          &
                           u_2(i+1,kts,j  )+          &
                           u_2(i+1,kts,j-1))/4)**2))+epsilon





       tao_yz=cd0*V0_v*v_2(i,kts,j)*(rho(i,kts,j)+rho(i,kts,j-1))/2.                        
       rv_tendf(i,kts,j)=rv_tendf(i,kts,j) +   g*tao_yz/dnw(kts)                            

       IF ( (config_flags%m_opt .EQ. 1) .OR. (config_flags%sfs_opt .GT. 0) ) THEN
          nba_mij(i,kts,j,P_m23) = -tao_yz
       ENDIF
    ENDDO
    ENDDO

  CASE (1,2) 
    DO j = j_start, j_end
    DO i = i_start, ite
       V0_u=0.
       tao_xz=0.
       V0_u=    sqrt((u_2(i,kts,j)**2) +         &
                        (((v_2(i  ,kts,j  )+          &
                           v_2(i  ,kts,j+1)+          &
                           v_2(i-1,kts,j  )+          &
                           v_2(i-1,kts,j+1))/4)**2))+epsilon
       ustar=0.5*(ust(i,j)+ust(i-1,j))





       tao_xz=ustar*ustar*u_2(i,kts,j)*(rho(i,kts,j)+rho(i-1,kts,j))/(2.*V0_u)              
       ru_tendf(i,kts,j)=ru_tendf(i,kts,j) +   g*tao_xz/dnw(kts)                            

       IF ( (config_flags%m_opt .EQ. 1) .OR. (config_flags%sfs_opt .GT. 0) ) THEN
          nba_mij(i,kts,j,P_m13) = -tao_xz
       ENDIF
    ENDDO
    ENDDO
 
    DO j = j_start, jte
    DO i = i_start, i_end
       V0_v=0.
       tao_yz=0.
       V0_v=    sqrt((v_2(i,kts,j)**2) +         &
                        (((u_2(i  ,kts,j  )+          &
                           u_2(i  ,kts,j-1)+          &
                           u_2(i+1,kts,j  )+          &
                           u_2(i+1,kts,j-1))/4)**2))+epsilon
       ustar=0.5*(ust(i,j)+ust(i,j-1))





       tao_yz=ustar*ustar*v_2(i,kts,j)*(rho(i,kts,j)+rho(i,kts,j-1))/(2.*V0_v)              
       rv_tendf(i,kts,j)=rv_tendf(i,kts,j) +   g*tao_yz/dnw(kts)                            

       IF ( (config_flags%m_opt .EQ. 1) .OR. (config_flags%sfs_opt .GT. 0) ) THEN
          nba_mij(i,kts,j,P_m23) = -tao_yz
       ENDIF
    ENDDO
    ENDDO

  CASE DEFAULT
    CALL wrf_error_fatal3("<stdin>",3702,&
'isfflx value invalid for diff_opt=2' )
  END SELECT vflux






   IF ( config_flags%mix_full_fields ) THEN

     DO j=jts,min(jte,jde-1)
     DO k=kts,kte-1
     DO i=its,min(ite,ide-1)
       var_mix(i,k,j) = thp(i,k,j)
     ENDDO
     ENDDO
     ENDDO

   ELSE

     DO j=jts,min(jte,jde-1)
     DO k=kts,kte-1
     DO i=its,min(ite,ide-1)
       var_mix(i,k,j) = thp(i,k,j) - t_base(k)
     ENDDO
     ENDDO
     ENDDO

   END IF

   CALL vertical_diffusion_s( rt_tendf, config_flags, var_mix, mu, xkhv, &
                              dn, dnw, rdz, rdzw, fnm, fnp, rho,     &     
                              .false.,                               &
                              ids, ide, jds, jde, kds, kde,          &
                              ims, ime, jms, jme, kms, kme,          &
                              its, ite, jts, jte, kts, kte          )







  hflux: SELECT CASE( config_flags%isfflx )
  CASE (0,2) 
    heat_flux = config_flags%tke_heat_flux  
                                            
    DO j = j_start, j_end
    DO i = i_start, i_end
       cpm = cp * (1. + 0.8 * moist(i,kts,j,P_QV)) 
       hfx(i,j)=heat_flux*cp*rho(i,kts,j)         



       rt_tendf(i,kts,j)=rt_tendf(i,kts,j)  &     
             -g*heat_flux*rho(i,kts,j)/dnw(kts)   

    ENDDO
    ENDDO

  CASE (1) 
    DO j = j_start, j_end
    DO i = i_start, i_end

       cpm = cp * (1. + 0.8 * moist(i,kts,j,P_QV))




       heat_flux = hfx(i,j)/cpm                 
       rt_tendf(i,kts,j)=rt_tendf(i,kts,j)  &   
            -g*heat_flux/dnw(kts)               


    ENDDO
    ENDDO

  CASE DEFAULT
    CALL wrf_error_fatal3("<stdin>",3781,&
'isfflx value invalid for diff_opt=2' )
  END SELECT hflux






   If (km_opt .eq. 2) then
   CALL vertical_diffusion_s( tke_tendf(ims,kms,jms),               &
                              config_flags, tke(ims,kms,jms),       &
                              mu, xkhv,                             &
                              dn, dnw, rdz, rdzw, fnm, fnp, rho,    &
                              .true.,                               &
                              ids, ide, jds, jde, kds, kde,         &
                              ims, ime, jms, jme, kms, kme,         &
                              its, ite, jts, jte, kts, kte         )
   endif
 
   IF (n_moist .ge. PARAM_FIRST_SCALAR) THEN 

     moist_loop: do im = PARAM_FIRST_SCALAR, n_moist

       IF ( (.not. config_flags%mix_full_fields) .and. (im == P_QV) ) THEN

         DO j=jts,min(jte,jde-1)
         DO k=kts,kte-1
         DO i=its,min(ite,ide-1)
          var_mix(i,k,j) = moist(i,k,j,im) - qv_base(k)
         ENDDO
         ENDDO
         ENDDO

       ELSE

         DO j=jts,min(jte,jde-1)
         DO k=kts,kte-1
         DO i=its,min(ite,ide-1)
          var_mix(i,k,j) = moist(i,k,j,im)
         ENDDO
         ENDDO
         ENDDO

       END IF


          CALL vertical_diffusion_s( moist_tendf(ims,kms,jms,im),         &
                                     config_flags, var_mix,               &
                                     mu, xkhv,                            &
                                     dn, dnw, rdz, rdzw, fnm, fnp, rho,   &
                                     .false.,                             &
                                     ids, ide, jds, jde, kds, kde,        &
                                     ims, ime, jms, jme, kms, kme,        &
                                     its, ite, jts, jte, kts, kte        )






  qflux: SELECT CASE( config_flags%isfflx )
  CASE (0)

  CASE (1,2) 
    IF ( im == P_QV ) THEN
       DO j = j_start, j_end
       DO i = i_start, i_end




          moist_flux = qfx(i,j)                                      
          moist_tendf(i,kts,j,im)=moist_tendf(i,kts,j,im)  &         
               -g*moist_flux/dnw(kts)                                

       ENDDO
       ENDDO
    ENDIF

  CASE DEFAULT
    CALL wrf_error_fatal3("<stdin>",3862,&
'isfflx value invalid for diff_opt=2' )
  END SELECT qflux




     ENDDO moist_loop

   ENDIF

   IF (n_chem .ge. PARAM_FIRST_SCALAR) THEN 

     chem_loop: do im = PARAM_FIRST_SCALAR, n_chem

          CALL vertical_diffusion_s( chem_tendf(ims,kms,jms,im),         &
                                     config_flags, chem(ims,kms,jms,im), &
                                     mu, xkhv,                             &
                                     dn, dnw, rdz, rdzw, fnm, fnp, rho,    &
                                     .false.,                              &
                                     ids, ide, jds, jde, kds, kde,         &
                                     ims, ime, jms, jme, kms, kme,         &
                                     its, ite, jts, jte, kts, kte         )
     ENDDO chem_loop

   ENDIF

   IF (n_tracer .ge. PARAM_FIRST_SCALAR) THEN 

     tracer_loop: do im = PARAM_FIRST_SCALAR, n_tracer

          CALL vertical_diffusion_s( tracer_tendf(ims,kms,jms,im),         &
                                     config_flags, tracer(ims,kms,jms,im), &
                                     mu, xkhv,                             &
                                     dn, dnw, rdz, rdzw, fnm, fnp, rho,    &
                                     .false.,                              &
                                     ids, ide, jds, jde, kds, kde,         &
                                     ims, ime, jms, jme, kms, kme,         &
                                     its, ite, jts, jte, kts, kte         )
     ENDDO tracer_loop

   ENDIF


   IF (n_scalar .ge. PARAM_FIRST_SCALAR) THEN 

     scalar_loop: do im = PARAM_FIRST_SCALAR, n_scalar

          CALL vertical_diffusion_s( scalar_tendf(ims,kms,jms,im),         &
                                     config_flags, scalar(ims,kms,jms,im), &
                                     mu, xkhv,                             &
                                     dn, dnw, rdz, rdzw, fnm, fnp, rho,    &
                                     .false.,                              &
                                     ids, ide, jds, jde, kds, kde,         &
                                     ims, ime, jms, jme, kms, kme,         &
                                     its, ite, jts, jte, kts, kte         )
     ENDDO scalar_loop

   ENDIF

END SUBROUTINE vertical_diffusion_2




SUBROUTINE vertical_diffusion_u_2( tendency, config_flags, mu,            &
                                   defor13, xkmv,                         &
                                   nba_mij, n_nba_mij,                    & 
                                   dnw, rdzw, fnm, fnp, rho,              &
                                   ids, ide, jds, jde, kds, kde,          &
                                   ims, ime, jms, jme, kms, kme,          &
                                   its, ite, jts, jte, kts, kte          )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,         INTENT(IN   ) ::       ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,            INTENT(IN   )      :: dnw


   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::tendency

   REAL , DIMENSION( ims:ime , kms:kme, jms:jme ) ,                       &
                                            INTENT(IN   )      ::defor13, &
                                                                    xkmv, &
                                                                    rdzw, &
                                                                     rho    

   INTEGER, INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij), INTENT(INOUT) &   
   :: nba_mij

   REAL , DIMENSION( ims:ime , jms:jme ) ,  INTENT(IN   )      :: mu



   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end
   INTEGER :: is_ext,ie_ext,js_ext,je_ext  

   REAL , DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1)        :: titau3

   REAL , DIMENSION( its:ite, jts:jte)                         ::  zzavg

   REAL :: rdzu




   ktf=MIN(kte,kde-1)
  
   i_start = its
   i_end   = ite
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-1,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = ite


   is_ext=0
   ie_ext=0
   js_ext=0
   je_ext=0
   CALL cal_titau_13_31( config_flags, titau3, defor13,   &
                         nba_mij(ims,kms,jms,P_m13),      & 
                         mu, xkmv, fnm, fnp, rho,         &
                         is_ext, ie_ext, js_ext, je_ext,  &
                         ids, ide, jds, jde, kds, kde,    &
                         ims, ime, jms, jme, kms, kme,    &
                         its, ite, jts, jte, kts, kte     )

      DO j = j_start, j_end
      DO k=kts+1,ktf
      DO i = i_start, i_end



        rdzu = -g/(dnw(k))                              

         tendency(i,k,j)=tendency(i,k,j)-rdzu*(titau3(i,k+1,j)-titau3(i,k,j))

      ENDDO
      ENDDO
      ENDDO




       DO j = j_start, j_end
       k=kts
       DO i = i_start, i_end



          rdzu = -g/dnw(k)                               

          tendency(i,k,j)=tendency(i,k,j)-rdzu*(titau3(i,k+1,j))
       ENDDO
       ENDDO


END SUBROUTINE vertical_diffusion_u_2




SUBROUTINE vertical_diffusion_v_2( tendency, config_flags, mu,            &
                                   defor23, xkmv,                         &
                                   nba_mij, n_nba_mij,                    & 
                                   dnw, rdzw, fnm, fnp, rho,              &
                                   ids, ide, jds, jde, kds, kde,          &
                                   ims, ime, jms, jme, kms, kme,          &
                                   its, ite, jts, jte, kts, kte          )



   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,         INTENT(IN   ) ::       ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,            INTENT(IN   )      :: dnw


   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::tendency

   REAL , DIMENSION( ims:ime , kms:kme, jms:jme ) ,                       &
                                            INTENT(IN   )      ::defor23, &
                                                                    xkmv, &
                                                                    rdzw, &
                                                                     rho       

   INTEGER, INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij),  INTENT(INOUT) &     
   :: nba_mij

   REAL , DIMENSION( ims:ime , jms:jme ) ,  INTENT(IN   )      :: mu



   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end
   INTEGER :: is_ext,ie_ext,js_ext,je_ext  

   REAL , DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1)        :: titau3

   REAL , DIMENSION( its:ite, jts:jte)                         ::  zzavg

   REAL  :: rdzv




   ktf=MIN(kte,kde-1)
  
   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = jte

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-1,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN(ite,ide-1)


   is_ext=0
   ie_ext=0
   js_ext=0
   je_ext=0
   CALL cal_titau_23_32( config_flags, titau3, defor23,   &
                         nba_mij(ims,kms,jms,P_m23),      & 
                         mu, xkmv, fnm, fnp, rho,         &
                         is_ext, ie_ext, js_ext, je_ext,  &
                         ids, ide, jds, jde, kds, kde,    &
                         ims, ime, jms, jme, kms, kme,    &
                         its, ite, jts, jte, kts, kte     )

   DO j = j_start, j_end
   DO k = kts+1,ktf
   DO i = i_start, i_end



      rdzv = - g / dnw(k)                            

      tendency(i,k,j)=tendency(i,k,j)-rdzv*(titau3(i,k+1,j)-titau3(i,k,j))

   ENDDO
   ENDDO
   ENDDO




       DO j = j_start, j_end
       k=kts
       DO i = i_start, i_end



       rdzv = - g / dnw(k)                             

        tendency(i,k,j)=tendency(i,k,j)-rdzv*(titau3(i,k+1,j))

       ENDDO
       ENDDO


END SUBROUTINE vertical_diffusion_v_2




SUBROUTINE vertical_diffusion_w_2(tendency, config_flags, mu,             &
                                defor33, tke,                             &
                                nba_mij, n_nba_mij,                       & 
                                div, xkmh,                                &
                                dn, rdz, fnm, fnp, rho,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                its, ite, jts, jte, kts, kte              )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,         INTENT(IN   ) ::       ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte
 
   REAL , DIMENSION( kms:kme ) ,            INTENT(IN   )      ::  dn, fnm, fnp


   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::tendency

   REAL , DIMENSION( ims:ime , kms:kme, jms:jme ) ,                       &
                                            INTENT(IN   )      ::defor33, &
                                                                     tke, &
                                                                     div, &
                                                                    xkmh, &
                                                                     rdz, &
                                                                     rho

   INTEGER, INTENT(  IN ) :: n_nba_mij 

   REAL , DIMENSION(ims:ime, kms:kme, jms:jme, n_nba_mij),  INTENT(INOUT) &   
   :: nba_mij

   REAL , DIMENSION( ims:ime, jms:jme), INTENT(IN   ) :: mu



   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end
   INTEGER :: is_ext,ie_ext,js_ext,je_ext  

   REAL , DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1)        :: titau3




   ktf=MIN(kte,kde-1)
  
   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN(ite,ide-1)


   is_ext=0
   ie_ext=0
   js_ext=0
   je_ext=0
   CALL cal_titau_11_22_33( config_flags, titau3,            &
                            mu, tke, xkmh, defor33,          & 
                            nba_mij(ims,kms,jms,P_m33), rho, & 
                            is_ext, ie_ext, js_ext, je_ext,  &
                            ids, ide, jds, jde, kds, kde,    &
                            ims, ime, jms, jme, kms, kme,    &
                            its, ite, jts, jte, kts, kte     )









   DO j = j_start, j_end
   DO k = kts+1, ktf
   DO i = i_start, i_end


       tendency(i,k,j)=tendency(i,k,j)+   g*(titau3(i,k,j)-titau3(i,k-1,j))/dn(k) 

   ENDDO
   ENDDO
   ENDDO

END SUBROUTINE vertical_diffusion_w_2




SUBROUTINE vertical_diffusion_s( tendency, config_flags, var, mu, xkhv,   &
                                 dn, dnw, rdz, rdzw, fnm, fnp, rho,       &
                                 doing_tke,                               &
                                 ids, ide, jds, jde, kds, kde,            &
                                 ims, ime, jms, jme, kms, kme,            &
                                 its, ite, jts, jte, kts, kte            )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,         INTENT(IN   ) ::       ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            its, ite, jts, jte, kts, kte

   LOGICAL,         INTENT(IN   ) ::        doing_tke

   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnm
   REAL , DIMENSION( kms:kme ) ,                 INTENT(IN   ) ::    fnp
   REAL , DIMENSION( kms:kme ) ,            INTENT(IN   )      ::  dn
   REAL , DIMENSION( kms:kme ) ,            INTENT(IN   )      :: dnw

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::tendency

   REAL , DIMENSION( ims:ime , kms:kme, jms:jme ) , INTENT(IN) ::   xkhv

   REAL , DIMENSION( ims:ime , jms:jme ) , INTENT(IN) ::   mu

   REAL , DIMENSION( ims:ime , kms:kme, jms:jme ) ,                       &
                                            INTENT(IN   )      ::    var, &
                                                                     rdz, &
                                                                    rdzw, &
                                                                     rho


   INTEGER :: i, j, k, ktf

   INTEGER :: i_start, i_end, j_start, j_end

   REAL , DIMENSION( its:ite, kts:kte, jts:jte)            ::        H3, &
                                                                 xkxavg, &
                                                                  rravg

   REAL , DIMENSION( its:ite, kts:kte, jts:jte)            ::  tmptendf




   ktf=MIN(kte,kde-1)
  
   i_start = its
   i_end   = MIN(ite,ide-1)
   j_start = jts
   j_end   = MIN(jte,jde-1)

   IF ( config_flags%open_xs .or. config_flags%specified .or. &
        config_flags%nested) i_start = MAX(ids+1,its)
   IF ( config_flags%open_xe .or. config_flags%specified .or. &
        config_flags%nested) i_end   = MIN(ide-2,ite)
   IF ( config_flags%open_ys .or. config_flags%specified .or. &
        config_flags%nested) j_start = MAX(jds+1,jts)
   IF ( config_flags%open_ye .or. config_flags%specified .or. &
        config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN(ite,ide-1)

   IF (doing_tke) THEN
      DO j = j_start, j_end
      DO k = kts,ktf
      DO i = i_start, i_end
         tmptendf(i,k,j)=tendency(i,k,j)
      ENDDO
      ENDDO
      ENDDO
   ENDIF



   xkxavg = 0.

   DO j = j_start, j_end
   DO k = kts+1,ktf
   DO i = i_start, i_end
      xkxavg(i,k,j)=fnm(k)*xkhv(i,k,j)+fnp(k)*xkhv(i,k-1,j) 
      xkxavg(i,k,j)=xkxavg(i,k,j)*(fnm(k)*rho(i,k,j)+fnp(k)*rho(i,k-1,j)) 
      H3(i,k,j)=-xkxavg(i,k,j)*(var(i,k,j)-var(i,k-1,j))*rdz(i,k,j)


   ENDDO
   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO i = i_start, i_end
      H3(i,kts,j)=0.
      H3(i,ktf+1,j)=0.


   ENDDO
   ENDDO

   DO j = j_start, j_end
   DO k = kts,ktf
   DO i = i_start, i_end



      tendency(i,k,j)=tendency(i,k,j)  &                            
                       +   g * (H3(i,k+1,j)-H3(i,k,j))/dnw(k)       

   ENDDO
   ENDDO
   ENDDO

   IF (doing_tke) THEN
      DO j = j_start, j_end
      DO k = kts,ktf
      DO i = i_start, i_end
          tendency(i,k,j)=tmptendf(i,k,j)+2.* &
                          (tendency(i,k,j)-tmptendf(i,k,j))
      ENDDO
      ENDDO
      ENDDO
   ENDIF

END SUBROUTINE vertical_diffusion_s




    SUBROUTINE cal_titau_11_22_33( config_flags, titau,              &
                                   mu, tke, xkx, defor,              &
                                   mtau, rho,                        & 
                                   is_ext, ie_ext, js_ext, je_ext,   &
                                   ids, ide, jds, jde, kds, kde,     &
                                   ims, ime, jms, jme, kms, kme,     &
                                   its, ite, jts, jte, kts, kte      )

















    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    INTEGER, INTENT( IN )  &
    :: is_ext, ie_ext, js_ext, je_ext  

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 ), INTENT( INOUT )  &
    :: titau 

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: defor, xkx, tke, rho                                          

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &  
    :: mtau                            

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: mu



    INTEGER  &
    :: i, j, k, ktf, i_start, i_end, j_start, j_end




    ktf = MIN( kte, kde-1 )

    i_start = its
    i_end   = ite
    j_start = jts
    j_end   = jte

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested) i_end   = MIN( ide-1, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-1, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = ite

    i_start = i_start - is_ext
    i_end   = i_end   + ie_ext   
    j_start = j_start - js_ext
    j_end   = j_end   + je_ext   

    IF ( config_flags%sfs_opt .GT. 0 ) THEN 

      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end

        titau(i,k,j) = rho(i,k,j) * mtau(i,k,j)  

      END DO
      END DO
      END DO  

    ELSE 

      IF ( config_flags%m_opt .EQ. 1 ) THEN 

        DO j = j_start, j_end
        DO k = kts, ktf
        DO i = i_start, i_end

          titau(i,k,j) = - rho(i,k,j) * xkx(i,k,j) * defor(i,k,j) 
          mtau(i,k,j) = - xkx(i,k,j) * defor(i,k,j) 
 
        END DO
        END DO
        END DO

      ELSE 

        DO j = j_start, j_end
        DO k = kts, ktf
        DO i = i_start, i_end

          titau(i,k,j) = - rho(i,k,j) * xkx(i,k,j) * defor(i,k,j) 

        END DO
        END DO
        END DO

      ENDIF 

    ENDIF 

    END SUBROUTINE cal_titau_11_22_33




    SUBROUTINE cal_titau_12_21( config_flags, titau,             &
                                mu, xkx, defor,                  &
                                mtau, rho,                       & 
                                is_ext, ie_ext, js_ext, je_ext,  &
                                ids, ide, jds, jde, kds, kde,    &
                                ims, ime, jms, jme, kms, kme,    &
                                its, ite, jts, jte, kts, kte     )

















    IMPLICIT NONE

    TYPE( grid_config_rec_type), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    INTEGER, INTENT( IN )  &
    :: is_ext, ie_ext, js_ext, je_ext  

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 ), INTENT( INOUT )  &
    :: titau 
 
    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: defor, xkx, rho                                              

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  & 
    :: mtau                              

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: mu



    INTEGER  &
    :: i, j, k, ktf, i_start, i_end, j_start, j_end

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 )  &
    :: xkxavg  

    REAL, DIMENSION( its-1:ite+1, jts-1:jte+1 )  &
    :: muavg




    ktf = MIN( kte, kde-1 )



    i_start = its
    i_end   = ite
    j_start = jts
    j_end   = jte

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested ) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested ) i_end   = MIN( ide-1, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested ) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested ) j_end   = MIN( jde-1, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = ite

    i_start = i_start - is_ext
    i_end   = i_end   + ie_ext   
    j_start = j_start - js_ext
    j_end   = j_end   + je_ext   

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      xkxavg(i,k,j) = 0.25 * ( xkx(i-1,k,j  ) + xkx(i,k,j  ) +  & 
                               xkx(i-1,k,j-1) + xkx(i,k,j-1) )    
      xkxavg(i,k,j) = xkxavg(i,k,j) * .25 * ( rho(i-1,k,j  ) + rho(i,k,j  )  +  & 
                                              rho(i-1,k,j-1) + rho(i,k,j-1) )     
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO i = i_start, i_end
      muavg(i,j) = 0.25 * ( mu(i-1,j  ) + mu(i,j  ) +  &
                            mu(i-1,j-1) + mu(i,j-1) )
    END DO
    END DO



    IF ( config_flags%sfs_opt .GT. 0 ) THEN 
 
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end

        titau(i,k,j) = rho(i,k,j) * mtau(i,k,j) 

      END DO
      END DO
      END DO

    ELSE 
  
      IF ( config_flags%m_opt .EQ. 1 ) THEN 

        DO j = j_start, j_end
        DO k = kts, ktf
        DO i = i_start, i_end
          titau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j) 
          mtau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j)  / rho(i,k,j)

        END DO
        END DO
        END DO

      ELSE 

        DO j = j_start, j_end
        DO k = kts, ktf
        DO i = i_start, i_end

          titau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j) 

        END DO
        END DO
        END DO

      ENDIF

    ENDIF 

    END SUBROUTINE cal_titau_12_21



    SUBROUTINE cal_titau_13_31( config_flags, titau,             &
                                defor,                           & 
                                mtau,                            & 
                                mu, xkx, fnm, fnp, rho,          &
                                is_ext, ie_ext, js_ext, je_ext,  &
                                ids, ide, jds, jde, kds, kde,    &
                                ims, ime, jms, jme, kms, kme,    &
                                its, ite, jts, jte, kts, kte     )

















    IMPLICIT NONE

    TYPE( grid_config_rec_type), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    INTEGER, INTENT( IN )  &
    :: is_ext, ie_ext, js_ext, je_ext  

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: fnm, fnp

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 ), INTENT( INOUT )  &
    :: titau 
 
    REAL, DIMENSION( ims:ime, kms:kme, jms:jme), INTENT( IN )  &
    :: defor, xkx, rho                                              

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  & 
    :: mtau                                      

    REAL, DIMENSION( ims:ime, jms:jme), INTENT( IN )  &
    :: mu



    INTEGER  &
    :: i, j, k, ktf, i_start, i_end, j_start, j_end

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 )  &
    :: xkxavg 

    REAL, DIMENSION( its-1:ite+1, jts-1:jte+1 )  &
    :: muavg




    ktf = MIN( kte, kde-1 )



    i_start = its
    i_end   = ite
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested) i_end   = MIN( ide-1, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-2, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = ite

    i_start = i_start - is_ext
    i_end   = i_end   + ie_ext   
    j_start = j_start - js_ext
    j_end   = j_end   + je_ext   

    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      xkxavg(i,k,j) = 0.5 * ( fnm(k) * ( xkx(i,k  ,j) + xkx(i-1,k  ,j) ) +  &  
                              fnp(k) * ( xkx(i,k-1,j) + xkx(i-1,k-1,j) ) )
      xkxavg(i,k,j) = xkxavg(i,k,j) * 0.5 * ( fnm(k) * ( rho(i-1,k  ,j) + rho(i,k  ,j) ) + &  
                                              fnp(k) * ( rho(i-1,k-1,j) + rho(i,k-1,j) ) )    
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO i = i_start, i_end
      muavg(i,j) = 0.5 * ( mu(i,j) + mu(i-1,j) )
    END DO
    END DO

    IF ( config_flags%sfs_opt .GT. 0 ) THEN 
 
      DO j = j_start, j_end
      DO k = kts+1, ktf
      DO i = i_start, i_end
         titau(i,k,j) = rho(i,k,j) * mtau(i,k,j)  
      ENDDO
      ENDDO
      ENDDO

    ELSE 
 
      IF ( config_flags%m_opt .EQ. 1 ) THEN 

        DO j = j_start, j_end
        DO k = kts+1, ktf
        DO i = i_start, i_end

          titau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j) 
          mtau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j)  / rho(i,k,j)
 
        ENDDO
        ENDDO
        ENDDO

      ELSE 

        DO j = j_start, j_end
        DO k = kts+1, ktf
        DO i = i_start, i_end

          titau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j) 

        ENDDO
        ENDDO
        ENDDO

      ENDIF  

    ENDIF 

    DO j = j_start, j_end
    DO i = i_start, i_end
      titau(i,kts  ,j) = 0.0
      titau(i,ktf+1,j) = 0.0
    ENDDO
    ENDDO

    END SUBROUTINE cal_titau_13_31




    SUBROUTINE cal_titau_23_32( config_flags, titau, defor,      &
                                mtau,                            & 
                                mu, xkx, fnm, fnp, rho,          &
                                is_ext, ie_ext, js_ext, je_ext,  &
                                ids, ide, jds, jde, kds, kde,    &
                                ims, ime, jms, jme, kms, kme,    &
                                its, ite, jts, jte, kts, kte     )

















    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    INTEGER, INTENT( IN )  &
    :: is_ext,ie_ext,js_ext,je_ext  

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: fnm, fnp

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 ), INTENT( INOUT )  &  
    :: titau 
 
    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: defor, xkx, rho                                              
  
    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  & 
    :: mtau                                             

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    ::  mu



    INTEGER  &
    :: i, j, k, ktf, i_start, i_end, j_start, j_end

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 )  &
    :: xkxavg 
                                                                   
    REAL, DIMENSION( its-1:ite+1, jts-1:jte+1 )  &
    :: muavg




     ktf = MIN( kte, kde-1 )



    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = jte

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested) i_end   = MIN( ide-2, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-1, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )

    i_start = i_start - is_ext
    i_end   = i_end   + ie_ext   
    j_start = j_start - js_ext
    j_end   = j_end   + je_ext   

    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      xkxavg(i,k,j) = 0.5 * ( fnm(k) * ( xkx(i,k  ,j) + xkx(i,k  ,j-1) ) +  & 
                              fnp(k) * ( xkx(i,k-1,j) + xkx(i,k-1,j-1) ) )    
      xkxavg(i,k,j) = xkxavg(i,k,j) * 0.5 * ( fnm(k) * ( rho(i,k  ,j) + rho(i,k  ,j-1) ) +  & 
                                              fnp(k) * ( rho(i,k-1,j) + rho(i,k-1,j-1) ) )    
    END DO
    END DO
    END DO
 
    DO j = j_start, j_end
    DO i = i_start, i_end
      muavg(i,j) = 0.5 * ( mu(i,j) + mu(i,j-1) )
    END DO
    END DO
 
    IF ( config_flags%sfs_opt .GT. 0 ) THEN 

      DO j = j_start, j_end
      DO k = kts+1, ktf
      DO i = i_start, i_end

        titau(i,k,j) =  rho(i,k,j) * mtau(i,k,j) 

      END DO
      END DO
      END DO

    ELSE 

      IF ( config_flags%m_opt .EQ. 1 ) THEN 

        DO j = j_start, j_end
        DO k = kts+1, ktf
        DO i = i_start, i_end

          titau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j)  
          mtau(i,k,j) = - xkxavg(i,k,j) * defor(i,k,j)  / rho(i,k,j)

        END DO
        END DO
        END DO

      ELSE 

        DO j = j_start, j_end
        DO k = kts+1, ktf
        DO i = i_start, i_end

          titau(i,k,j) = -  xkxavg(i,k,j) * defor(i,k,j) 

        END DO
        END DO
        END DO

      ENDIF 

    ENDIF 

    DO j = j_start, j_end
    DO i = i_start, i_end
      titau(i,kts  ,j) = 0.0
      titau(i,ktf+1,j) = 0.0
    END DO
    END DO

    END SUBROUTINE cal_titau_23_32




SUBROUTINE phy_bc ( config_flags,div,defor11,defor22,defor33,              &
                    defor12,defor13,defor23,xkmh,xkmv,xkhh,xkhv,tke,rho,   &
                    RUBLTEN, RVBLTEN,                                      &
                    RUCUTEN, RVCUTEN,                                      &
                    RUSHTEN, RVSHTEN,                                      &
                    ids, ide, jds, jde, kds, kde,                          &
                    ims, ime, jms, jme, kms, kme,                          &
                    ips, ipe, jps, jpe, kps, kpe,                          &
                    its, ite, jts, jte, kts, kte                           )




   IMPLICIT NONE

   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) ::        ids, ide, jds, jde, kds, kde, &
                                            ims, ime, jms, jme, kms, kme, &
                                            ips, ipe, jps, jpe, kps, kpe, &
                                            its, ite, jts, jte, kts, kte

   REAL , DIMENSION( ims:ime, kms:kme, jms:jme), INTENT(INOUT) ::RUBLTEN, &
                                                                 RVBLTEN, &
                                                                 RUCUTEN, &
                                                                 RVCUTEN, &
                                                                 RUSHTEN, &
                                                                 RVSHTEN, &
                                                                 defor11, &
                                                                 defor22, &
                                                                 defor33, &
                                                                 defor12, &
                                                                 defor13, &
                                                                 defor23, &
                                                                    xkmh, &
                                                                    xkmv, &
                                                                    xkhh, &
                                                                    xkhv, &
                                                                     tke, &
                                                                     div, &
                                                                     rho 




   IF(config_flags%bl_pbl_physics .GT. 0) THEN

        CALL set_physical_bc3d( RUBLTEN , 't', config_flags,              &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

        CALL set_physical_bc3d( RVBLTEN , 't', config_flags,              &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   ENDIF

   IF(config_flags%cu_physics .GT. 0) THEN

        CALL set_physical_bc3d( RUCUTEN , 't', config_flags,              &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

        CALL set_physical_bc3d( RVCUTEN , 't', config_flags,              &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   ENDIF

   IF(config_flags%shcu_physics .GT. 0) THEN

        CALL set_physical_bc3d( RUSHTEN , 't', config_flags,              &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

        CALL set_physical_bc3d( RVSHTEN , 't', config_flags,              &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   ENDIF

   
   

   CALL set_physical_bc3d( xkmh    , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( xkhh    , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   IF(config_flags%diff_opt .eq. 2) THEN

   CALL set_physical_bc3d( xkmv    , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( xkhv    , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( div     , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( defor11 , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( defor22 , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( defor33 , 't', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( defor12 , 'd', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( defor13 , 'e', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( defor23 , 'f', config_flags,                   &
                                ids, ide, jds, jde, kds, kde,             &
                                ims, ime, jms, jme, kms, kme,             &
                                ips, ipe, jps, jpe, kps, kpe,             &
                                its, ite, jts, jte, kts, kte              )

   CALL set_physical_bc3d( rho , 't', config_flags,                       &  
                                ids, ide, jds, jde, kds, kde,             &  
                                ims, ime, jms, jme, kms, kme,             &  
                                ips, ipe, jps, jpe, kps, kpe,             &  
                                its, ite, jts, jte, kts, kte              )  
   ENDIF

END SUBROUTINE phy_bc 




    SUBROUTINE tke_rhs( tendency, BN2, config_flags,            &
                        defor11, defor22, defor33,              &
                        defor12, defor13, defor23,              &
                        u, v, w, div, tke, mu,                  &
                        theta, p, p8w, t8w, z, fnm, fnp,        &
                        cf1, cf2, cf3, msftx, msfty,            &
                        xkmh, xkmv, xkhv,                       &
                        rdx, rdy, dx, dy, dt, zx, zy,           &
                        rdz, rdzw, dn, dnw, isotropic,          &
                        hfx, qfx, qv, ust, rho,                 &
                        ids, ide, jds, jde, kds, kde,           &
                        ims, ime, jms, jme, kms, kme,           &
                        its, ite, jts, jte, kts, kte            )




    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    INTEGER, INTENT( IN )  :: isotropic
    REAL, INTENT( IN )  &
    :: cf1, cf2, cf3, dt, rdx, rdy, dx, dy

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: fnm, fnp, dnw, dn

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: msftx, msfty

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: tendency

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: defor11, defor22, defor33, defor12, defor13, defor23,  &
       div, BN2, tke, xkmh, xkmv, xkhv, zx, zy, u, v, w, theta,  &
       p, p8w, t8w, z, rdz, rdzw

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: mu

    REAL, DIMENSION ( ims:ime, jms:jme ), INTENT( IN )   &
    :: hfx, ust, qfx
    REAL, DIMENSION ( ims:ime, kms:kme, jms:jme ), INTENT ( IN ) &
    :: qv, rho



    INTEGER  &
    :: i, j, k, ktf, i_start, i_end, j_start, j_end




    CALL tke_shear(    tendency, config_flags,                &
                       defor11, defor22, defor33,             &
                       defor12, defor13, defor23,             &
                       u, v, w, tke, ust, mu, fnm, fnp,       &
                       cf1, cf2, cf3, msftx, msfty,           &
                       xkmh, xkmv,                            &
                       rdx, rdy, zx, zy, rdz, rdzw, dnw, dn,  &
                       ids, ide, jds, jde, kds, kde,          &
                       ims, ime, jms, jme, kms, kme,          &
                       its, ite, jts, jte, kts, kte           )

    CALL tke_buoyancy( tendency, config_flags, mu,            &
                       tke, xkhv, BN2, theta, dt,             &
                       hfx, qfx, qv,  rho,                    &
                       ids, ide, jds, jde, kds, kde,          &
                       ims, ime, jms, jme, kms, kme,          &
                       its, ite, jts, jte, kts, kte           ) 

    CALL tke_dissip(   tendency, config_flags,                &
                       mu, tke, bn2, theta, p8w, t8w, z,      &
                       dx, dy,rdz, rdzw, isotropic,           &
                       msftx, msfty,                          &
                       ids, ide, jds, jde, kds, kde,          &
                       ims, ime, jms, jme, kms, kme,          &
                       its, ite, jts, jte, kts, kte           )



    ktf     = MIN( kte, kde-1 )
    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .or. config_flags%specified .or. &
         config_flags%nested) i_start = MAX(ids+1,its)
    IF ( config_flags%open_xe .or. config_flags%specified .or. &
         config_flags%nested) i_end   = MIN(ide-2,ite)
    IF ( config_flags%open_ys .or. config_flags%specified .or. &
         config_flags%nested) j_start = MAX(jds+1,jts)
    IF ( config_flags%open_ye .or. config_flags%specified .or. &
         config_flags%nested) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )
 
    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = max( tendency(i,k,j), -mu(i,j) * max( 0.0 , tke(i,k,j) ) / dt )
    END DO
    END DO
    END DO

    END SUBROUTINE tke_rhs




    SUBROUTINE tke_buoyancy( tendency, config_flags, mu,    &
                             tke, xkhv, BN2, theta, dt,     &
                             hfx, qfx, qv,  rho,            &
                             ids, ide, jds, jde, kds, kde,  &
                             ims, ime, jms, jme, kms, kme,  &
                             its, ite, jts, jte, kts, kte   )




    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    REAL, INTENT( IN )  &
    :: dt

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: tendency

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: xkhv, tke, BN2, theta 

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: mu

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT ( IN ) &
    :: qv, rho

    REAL, DIMENSION(ims:ime, jms:jme ), INTENT ( IN ) :: hfx, qfx
 


    INTEGER  &
    :: i, j, k, ktf

    INTEGER  &
    :: i_start, i_end, j_start, j_end

    REAL :: heat_flux, heat_flux0

    REAL :: cpm








    ktf     = MIN( kte, kde-1 )
    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested ) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested ) i_end   = MIN( ide-2, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested ) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested ) j_end   = MIN( jde-2, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )
 
    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = tendency(i,k,j) - mu(i,j) * xkhv(i,k,j) * BN2(i,k,j)
    END DO
    END DO
    END DO







  hflux: SELECT CASE( config_flags%isfflx )
  CASE (0,2) 
   heat_flux0 = config_flags%tke_heat_flux  
                                            

   K=KTS
   DO j = j_start, j_end
   DO i = i_start, i_end 
      heat_flux = heat_flux0 
      tendency(i,k,j)= tendency(i,k,j) - &
                   mu(i,j)*((xkhv(i,k,j)*BN2(i,k,j))- (g/theta(i,k,j))*heat_flux)/2.

   ENDDO
   ENDDO   

  CASE (1) 
   K=KTS
   DO j = j_start, j_end
   DO i = i_start, i_end 
      cpm = cp * (1. + 0.8*qv(i,k,j))
      heat_flux = (hfx(i,j)/cpm)/rho(i,k,j)

      tendency(i,k,j)= tendency(i,k,j) - &
                   mu(i,j)*((xkhv(i,k,j)*BN2(i,k,j))- (g/theta(i,k,j))*heat_flux)/2.

   ENDDO
   ENDDO   

  CASE DEFAULT
    CALL wrf_error_fatal3("<stdin>",5426,&
'isfflx value invalid for diff_opt=2' )
  END SELECT hflux







    END SUBROUTINE tke_buoyancy




    SUBROUTINE tke_dissip( tendency, config_flags,            &
                           mu, tke, bn2, theta, p8w, t8w, z,  &
                           dx, dy, rdz, rdzw, isotropic,      &
                           msftx, msfty,                      &
                           ids, ide, jds, jde, kds, kde,      &
                           ims, ime, jms, jme, kms, kme,      &
                           its, ite, jts, jte, kts, kte       )















    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    ::  ids, ide, jds, jde, kds, kde,  &
        ims, ime, jms, jme, kms, kme,  &
        its, ite, jts, jte, kts, kte

    INTEGER, INTENT( IN )  :: isotropic
    REAL, INTENT( IN )  &
    :: dx, dy
 
    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: tendency
 
    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: tke, bn2, theta, p8w, t8w, z, rdz, rdzw

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: mu

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: msftx, msfty


    REAL, DIMENSION( its:ite, kts:kte, jts:jte )  &
    :: dthrdn

    REAL, DIMENSION( its:ite, kts:kte, jts:jte )  &
    :: l_scale

    REAL, DIMENSION( its:ite )  & 
    :: sumtke,  sumtkez

    INTEGER  &
    :: i, j, k, ktf, i_start, i_end, j_start, j_end

    REAL  &
    :: disp_len, deltas, coefc, tmpdz, len_s, thetasfc,  &
       thetatop, len_0, tketmp, tmp, ce1, ce2, c_k



    c_k = config_flags%c_k

    ce1 = ( c_k / 0.10 ) * 0.19
    ce2 = max( 0.0 , 0.93 - ce1 )

    ktf     = MIN( kte, kde-1 )
    i_start = its
    i_end   = MIN(ite,ide-1)
    j_start = jts
    j_end   = MIN(jte,jde-1)

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested) i_end   = MIN( ide-2, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-2, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )

      CALL calc_l_scale( config_flags, tke, BN2, l_scale,      &
                         i_start, i_end, ktf, j_start, j_end,  &
                         dx, dy, rdzw, msftx, msfty,           &
                         ids, ide, jds, jde, kds, kde,         &
                         ims, ime, jms, jme, kms, kme,         &
                         its, ite, jts, jte, kts, kte          )
      DO j = j_start, j_end
      DO k = kts, ktf
      DO i = i_start, i_end
        deltas  = ( dx/msftx(i,j) * dy/msfty(i,j) / rdzw(i,k,j) )**0.33333333
        tketmp  = MAX( tke(i,k,j), 1.0e-6 )




        IF ( k .eq. kts .or. k .eq. ktf ) then
          coefc = 3.9
        ELSE
          coefc = ce1 + ce2 * l_scale(i,k,j) / deltas
        END IF

        tendency(i,k,j) = tendency(i,k,j) - &
                          mu(i,j) * coefc * tketmp**1.5 / l_scale(i,k,j)
      END DO
      END DO
      END DO

    END SUBROUTINE tke_dissip




    SUBROUTINE tke_shear( tendency, config_flags,                &
                          defor11, defor22, defor33,             &
                          defor12, defor13, defor23,             &
                          u, v, w, tke, ust, mu, fnm, fnp,       &
                          cf1, cf2, cf3, msftx, msfty,           &
                          xkmh, xkmv,                            &
                          rdx, rdy, zx, zy, rdz, rdzw, dn, dnw,  &
                          ids, ide, jds, jde, kds, kde,          &
                          ims, ime, jms, jme, kms, kme,          &
                          its, ite, jts, jte, kts, kte           )











































    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    REAL, INTENT( IN )  &
    :: cf1, cf2, cf3, rdx, rdy

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: fnm, fnp, dn, dnw

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: msftx, msfty

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( INOUT )  &
    :: tendency

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &  
    :: defor11, defor22, defor33, defor12, defor13, defor23,    &
       tke, xkmh, xkmv, zx, zy, u, v, w, rdz, rdzw

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: mu

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( IN )  &
    :: ust



    INTEGER  &
    :: i, j, k, ktf, ktes1, ktes2,      &
       i_start, i_end, j_start, j_end,  &
       is_ext, ie_ext, js_ext, je_ext   

    REAL  &
    :: mtau

    REAL, DIMENSION( its-1:ite+1, kts:kte, jts-1:jte+1 )  &
    :: avg, titau, tmp2

    REAL, DIMENSION( its:ite, kts:kte, jts:jte )  &
    :: titau12, tmp1, zxavg, zyavg

    REAL :: absU, cd0, Cd




    ktf    = MIN( kte, kde-1 )
    ktes1  = kte-1
    ktes2  = kte-2
   
    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested ) i_start = MAX( ids+1, its )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested ) i_end   = MIN( ide-2, ite )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested ) j_start = MAX( jds+1, jts )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested ) j_end   = MIN( jde-2, jte )
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN( ite, ide-1 )

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      zxavg(i,k,j) = 0.25 * ( zx(i,k  ,j) + zx(i+1,k  ,j) + &
                              zx(i,k+1,j) + zx(i+1,k+1,j)  )
      zyavg(i,k,j) = 0.25 * ( zy(i,k  ,j) + zy(i,k  ,j+1) + &
                              zy(i,k+1,j) + zy(i,k+1,j+1)  )
    END DO
    END DO
    END DO










    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = tendency(i,k,j) + 0.5 *  &
                        mu(i,j) * xkmh(i,k,j) * ( ( defor11(i,k,j) )**2 )
    END DO
    END DO
    END DO



    DO j = j_start, j_end 
    DO k = kts, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = tendency(i,k,j) + 0.5 *  &
                        mu(i,j) * xkmh(i,k,j) * ( ( defor22(i,k,j) )**2 )
    END DO
    END DO
    END DO



    DO j = j_start, j_end 
    DO k = kts, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = tendency(i,k,j) + 0.5 *  &
                        mu(i,j) * xkmv(i,k,j) * ( ( defor33(i,k,j) )**2 )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      avg(i,k,j) = 0.25 *  &
                   ( ( defor12(i  ,k,j)**2 ) + ( defor12(i  ,k,j+1)**2 ) +  &
                     ( defor12(i+1,k,j)**2 ) + ( defor12(i+1,k,j+1)**2 ) )
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = tendency(i,k,j) + mu(i,j) * xkmh(i,k,j) * avg(i,k,j)
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end+1
      tmp2(i,k,j) = defor13(i,k,j)
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO i = i_start, i_end+1
      tmp2(i,kts  ,j) = 0.0
      tmp2(i,ktf+1,j) = 0.0
    END DO
    END DO

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      avg(i,k,j) = 0.25 *  &
                   ( ( tmp2(i  ,k+1,j)**2 ) + ( tmp2(i  ,k,j)**2 ) +  &
                     ( tmp2(i+1,k+1,j)**2 ) + ( tmp2(i+1,k,j)**2 ) )
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = tendency(i,k,j) + mu(i,j) * xkmv(i,k,j) * avg(i,k,j)
    END DO
    END DO
    END DO


    K=KTS

  uflux: SELECT CASE( config_flags%isfflx )
  CASE (0) 

    cd0 = config_flags%tke_drag_coefficient  
                                             
    DO j = j_start, j_end   
    DO i = i_start, i_end

      absU=0.5*sqrt((u(i,k,j)+u(i+1,k,j))**2+(v(i,k,j)+v(i,k,j+1))**2)
      Cd = cd0
      tendency(i,k,j) = tendency(i,k,j) +       &
           mu(i,j)*( (u(i,k,j)+u(i+1,k,j))*0.5* &
                     Cd*absU*(defor13(i,kts+1,j)+defor13(i+1,kts+1,j))*0.5 )

    END DO
    END DO

  CASE (1,2) 

    DO j = j_start, j_end
    DO i = i_start, i_end

      absU=0.5*sqrt((u(i,k,j)+u(i+1,k,j))**2+(v(i,k,j)+v(i,k,j+1))**2)+epsilon
      Cd = (ust(i,j)**2)/(absU**2)
      tendency(i,k,j) = tendency(i,k,j) +       &
           mu(i,j)*( (u(i,k,j)+u(i+1,k,j))*0.5* &
                     Cd*absU*(defor13(i,kts+1,j)+defor13(i+1,kts+1,j))*0.5 )

    END DO
    END DO

  CASE DEFAULT
    CALL wrf_error_fatal3("<stdin>",5829,&
'isfflx value invalid for diff_opt=2' )
  END SELECT uflux




    DO j = j_start, j_end+1
    DO k = kts+1, ktf
    DO i = i_start, i_end
      tmp2(i,k,j) = defor23(i,k,j)
    END DO
    END DO
    END DO

    DO j = j_start, j_end+1
    DO i = i_start, i_end
      tmp2(i,kts,  j) = 0.0
      tmp2(i,ktf+1,j) = 0.0
    END DO
    END DO

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      avg(i,k,j) = 0.25 *  &
                   ( ( tmp2(i,k+1,j  )**2 ) + ( tmp2(i,k,j  )**2) +  &
                     ( tmp2(i,k+1,j+1)**2 ) + ( tmp2(i,k,j+1)**2) )
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tendency(i,k,j) = tendency(i,k,j) + mu(i,j) * xkmv(i,k,j) * avg(i,k,j)
    END DO
    END DO
    END DO


    K=KTS

  vflux: SELECT CASE( config_flags%isfflx )
  CASE (0) 

    cd0 = config_flags%tke_drag_coefficient   
                                              
    DO j = j_start, j_end   
    DO i = i_start, i_end

      absU=0.5*sqrt((u(i,k,j)+u(i+1,k,j))**2+(v(i,k,j)+v(i,k,j+1))**2)
      Cd = cd0
      tendency(i,k,j) = tendency(i,k,j) +       &
           mu(i,j)*( (v(i,k,j)+v(i,k,j+1))*0.5* &
                     Cd*absU*(defor23(i,kts+1,j)+defor23(i,kts+1,j+1))*0.5 )

    END DO
    END DO

  CASE (1,2) 

    DO j = j_start, j_end   
    DO i = i_start, i_end

      absU=0.5*sqrt((u(i,k,j)+u(i+1,k,j))**2+(v(i,k,j)+v(i,k,j+1))**2)+epsilon
      Cd = (ust(i,j)**2)/(absU**2)
      tendency(i,k,j) = tendency(i,k,j) +       &
           mu(i,j)*( (v(i,k,j)+v(i,k,j+1))*0.5* &
                     Cd*absU*(defor23(i,kts+1,j)+defor23(i,kts+1,j+1))*0.5 )

    END DO
    END DO

  CASE DEFAULT
    CALL wrf_error_fatal3("<stdin>",5904,&
'isfflx value invalid for diff_opt=2' )
  END SELECT vflux


    END SUBROUTINE tke_shear




    SUBROUTINE compute_diff_metrics( config_flags, ph, phb, z, rdz, rdzw,  &
                                     zx, zy, rdx, rdy,                     &
                                     ids, ide, jds, jde, kds, kde,         &
                                     ims, ime, jms, jme, kms, kme,         &
                                     its, ite, jts, jte, kts, kte         )




    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde,  &
       ims, ime, jms, jme, kms, kme,  &
       its, ite, jts, jte, kts, kte

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    :: ph, phb

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( OUT )  &
    :: rdz, rdzw, zx, zy, z


    REAL, INTENT( IN )  &
    :: rdx, rdy



    REAL, DIMENSION( its-1:ite, kts:kte, jts-1:jte )  &
    :: z_at_w

    INTEGER  &
    :: i, j, k, i_start, i_end, j_start, j_end, ktf




    ktf = MIN( kte, kde-1 )





    j_start = jts-1
    j_end   = jte



    DO j = j_start, j_end

      IF ( ( j_start >= jts ) .AND. ( j_end <= MIN( jte, jde-1 ) ) ) THEN
        i_start = its-1
        i_end   = ite
      ELSE
        i_start = its
        i_end   = MIN( ite, ide-1 )
      END IF




      DO k = 1, kte



      DO i = i_start, i_end
        z_at_w(i,k,j) = ( ph(i,k,j) + phb(i,k,j) ) / g
      END DO
      END DO

      DO k = 1, ktf
      DO i = i_start, i_end
        rdzw(i,k,j) = 1.0 / ( z_at_w(i,k+1,j) - z_at_w(i,k,j) )
      END DO
      END DO

      DO k = 2, ktf
      DO i = i_start, i_end
        rdz(i,k,j) = 2.0 / ( z_at_w(i,k+1,j) - z_at_w(i,k-1,j) )
      END DO
      END DO



      DO i = i_start, i_end
        rdz(i,1,j) = 2./(z_at_w(i,2,j)-z_at_w(i,1,j))
      END DO

    END DO






    i_start = its
    i_end   = MIN( ite, ide-1 )
    j_start = jts
    j_end   = MIN( jte, jde-1 )

    DO j = j_start, j_end
    DO k = 1, kte
    DO i = MAX( ids+1, its ), i_end
      zx(i,k,j) = rdx * ( phb(i,k,j) - phb(i-1,k,j) ) / g
    END DO
    END DO
    END DO

    DO j = j_start, j_end
    DO k = 1, kte
    DO i = MAX( ids+1, its ), i_end
      zx(i,k,j) = zx(i,k,j) + rdx * ( ph(i,k,j) - ph(i-1,k,j) ) / g
    END DO
    END DO
    END DO

    DO j = MAX( jds+1, jts ), j_end
    DO k = 1, kte
    DO i = i_start, i_end
      zy(i,k,j) = rdy * ( phb(i,k,j) - phb(i,k,j-1) ) / g
    END DO
    END DO
    END DO

    DO j = MAX( jds+1, jts ), j_end
    DO k = 1, kte
    DO i = i_start, i_end
      zy(i,k,j) = zy(i,k,j) + rdy * ( ph(i,k,j) - ph(i,k,j-1) ) / g
    END DO
    END DO
    END DO



    IF ( .NOT. config_flags%periodic_x ) THEN

      IF ( ite == ide ) THEN
        DO j = j_start, j_end
        DO k = 1, ktf
          zx(ide,k,j) = 0.0
        END DO
        END DO
      END IF

      IF ( its == ids ) THEN
        DO j = j_start, j_end
        DO k = 1, ktf
          zx(ids,k,j) = 0.0
        END DO
        END DO
      END IF

    ELSE

      IF ( ite == ide ) THEN
        DO j=j_start,j_end
        DO k=1,ktf
         zx(ide,k,j) = rdx * ( phb(ide,k,j) - phb(ide-1,k,j) ) / g
        END DO
        END DO

        DO j = j_start, j_end
        DO k = 1, ktf
          zx(ide,k,j) = zx(ide,k,j) + rdx * ( ph(ide,k,j) - ph(ide-1,k,j) ) / g
        END DO
        END DO
      END IF

      IF ( its == ids ) THEN
        DO j = j_start, j_end
        DO k = 1, ktf
          zx(ids,k,j) = rdx * ( phb(ids,k,j) - phb(ids-1,k,j) ) / g
        END DO
        END DO

        DO j =j_start,j_end
        DO k =1,ktf
          zx(ids,k,j) = zx(ids,k,j) + rdx * ( ph(ids,k,j) - ph(ids-1,k,j) ) / g
        END DO
        END DO
      END IF

    END IF

    IF ( .NOT. config_flags%periodic_y ) THEN

      IF ( jte == jde ) THEN
        DO k =1, ktf
        DO i =i_start, i_end
          zy(i,k,jde) = 0.0
        END DO
        END DO
      END IF

      IF ( jts == jds ) THEN
        DO k =1, ktf
        DO i =i_start, i_end
          zy(i,k,jds) = 0.0
        END DO
        END DO
      END IF

    ELSE

      IF ( jte == jde ) THEN
        DO k=1, ktf
        DO i =i_start, i_end
          zy(i,k,jde) = rdy * ( phb(i,k,jde) - phb(i,k,jde-1) ) / g
        END DO
        END DO

        DO k = 1, ktf
        DO i =i_start, i_end
          zy(i,k,jde) = zy(i,k,jde) + rdy * ( ph(i,k,jde) - ph(i,k,jde-1) ) / g
        END DO
        END DO
      END IF

      IF ( jts == jds ) THEN
        DO k = 1, ktf
        DO i =i_start, i_end
          zy(i,k,jds) = rdy * ( phb(i,k,jds) - phb(i,k,jds-1) ) / g
        END DO
        END DO

        DO k = 1, ktf
        DO i =i_start, i_end
          zy(i,k,jds) = zy(i,k,jds) + rdy * ( ph(i,k,jds) - ph(i,k,jds-1) ) / g
        END DO
        END DO
      END IF

    END IF
      


    DO j = j_start, j_end
      DO k = 1, ktf
      DO i = i_start, i_end
        z(i,k,j) = 0.5 *  &
                   ( ph(i,k,j) + phb(i,k,j) + ph(i,k+1,j) + phb(i,k+1,j) ) / g
      END DO
      END DO
    END DO

    END SUBROUTINE compute_diff_metrics

    SUBROUTINE cal_helicity ( config_flags, u, v, w, uh, up_heli_max,&
                                   ph, phb,                          &
                                   msfux, msfuy,                     &
                                   msfvx, msfvy,                     &
                                   ht,                               &
                                   rdx, rdy, dn, dnw, rdz, rdzw,     &
                                   fnm, fnp, cf1, cf2, cf3, zx, zy,  &
                                   ids, ide, jds, jde, kds, kde,     &
                                   ims, ime, jms, jme, kms, kme,     &
                                   its, ite, jts, jte, kts, kte      )














    IMPLICIT NONE

    TYPE( grid_config_rec_type ), INTENT( IN )  &
    :: config_flags

    INTEGER, INTENT( IN )  &
    :: ids, ide, jds, jde, kds, kde, &
       ims, ime, jms, jme, kms, kme, &
       its, ite, jts, jte, kts, kte

    REAL, INTENT( IN )  &
    :: rdx, rdy, cf1, cf2, cf3

    REAL, DIMENSION( kms:kme ), INTENT( IN )  &
    :: fnm, fnp, dn, dnw

    REAL, DIMENSION( ims:ime , jms:jme ),  INTENT( IN )  &
    :: msfux, msfuy, msfvx, msfvy, ht

    REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT( IN )  &
    ::  u, v, w, ph, phb, zx, zy, rdz, rdzw

    REAL, DIMENSION( ims:ime, jms:jme ), INTENT( INOUT )  &
    :: uh, up_heli_max



    INTEGER  &
    :: i, j, k, ktf, ktes1, ktes2, i_start, i_end, j_start, j_end

    REAL  &
    :: tmp, tmpzx, tmpzy, tmpzeta_z, cft1, cft2

    REAL  &
    :: zl, zu, uh_smth

    REAL, DIMENSION( its-3:ite+2, jts-3:jte+2 )  :: mm

    REAL, DIMENSION( its-3:ite+2, kts:kte, jts-3:jte+2 )  &
    :: tmp1, hat, hatavg

    REAL, DIMENSION( its-3:ite+2, kts:kte, jts-3:jte+2 )  &
    :: wavg, rvort

    LOGICAL, DIMENSION( its-3:ite+2, jts-3:jte+2 )  &
    :: use_column









    ktes1   = kte-1
    ktes2   = kte-2

    cft2    = - 0.5 * dnw(ktes1) / dn(ktes1)
    cft1    = 1.0 - cft2

    ktf     = MIN( kte, kde-1 )



    i_start = its
    i_end   = ite
    j_start = jts
    j_end   = jte

    IF ( config_flags%open_xs .OR. config_flags%specified .OR. &
         config_flags%nested) i_start = MAX( ids+1, its-2 )
    IF ( config_flags%open_xe .OR. config_flags%specified .OR. &
         config_flags%nested) i_end   = MIN( ide-1, ite+2 )
    IF ( config_flags%open_ys .OR. config_flags%specified .OR. &
         config_flags%nested) j_start = MAX( jds+1, jts-2 )
    IF ( config_flags%open_ye .OR. config_flags%specified .OR. &
         config_flags%nested) j_end   = MIN( jde-1, jte+2 )
    IF ( config_flags%periodic_x ) i_start = its
    IF ( config_flags%periodic_x ) i_end = ite













    DO j = j_start, j_end
    DO i = i_start, i_end
      mm(i,j) = 0.25 * ( msfux(i,j-1) + msfux(i,j) ) * ( msfvy(i-1,j) + msfvy(i,j) )
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start-1, i_end
       hat(i,k,j) = v(i,k,j) / msfvy(i,j)
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO k = kts+1, ktf
    DO i = i_start, i_end
      hatavg(i,k,j) = 0.5 * (  &
                      fnm(k) * ( hat(i-1,k  ,j) + hat(i,k  ,j) ) +  &
                      fnp(k) * ( hat(i-1,k-1,j) + hat(i,k-1,j) ) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO i = i_start, i_end
       hatavg(i,1,j)   =  0.5 * (  &
                          cf1 * hat(i-1,1,j) +  &
                          cf2 * hat(i-1,2,j) +  &
                          cf3 * hat(i-1,3,j) +  &
                          cf1 * hat(i  ,1,j) +  &
                          cf2 * hat(i  ,2,j) +  &
                          cf3 * hat(i  ,3,j) )
       hatavg(i,kte,j) =  0.5 * (  &
                          cft1 * ( hat(i,ktes1,j) + hat(i-1,ktes1,j) ) +  &
                          cft2 * ( hat(i,ktes2,j) + hat(i-1,ktes2,j) ) )
    END DO
    END DO

    
    
    
    
    
    
    
    
    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmpzx       = 0.25 * (  &
                    zx(i,k  ,j-1) + zx(i,k  ,j) +  &
                    zx(i,k+1,j-1) + zx(i,k+1,j) )
      tmp1(i,k,j) = ( hatavg(i,k+1,j) - hatavg(i,k,j) ) *  &
                    0.25 * tmpzx * ( rdzw(i,k,j) + rdzw(i,k,j-1) + &
                                     rdzw(i-1,k,j-1) + rdzw(i-1,k,j) )
    END DO
    END DO
    END DO








    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      rvort(i,k,j) = mm(i,j) * (  &
                     rdx * ( hat(i,k,j) - hat(i-1,k,j) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO









    DO j =j_start-1, j_end
    DO k =kts, ktf
    DO i =i_start, i_end
      
      
      hat(i,k,j) = u(i,k,j) / msfux(i,j)
    END DO
    END DO
    END DO



    DO j=j_start,j_end
    DO k=kts+1,ktf
    DO i=i_start,i_end
      hatavg(i,k,j) = 0.5 * (  &
                      fnm(k) * ( hat(i,k  ,j-1) + hat(i,k  ,j) ) +  &
                      fnp(k) * ( hat(i,k-1,j-1) + hat(i,k-1,j) ) )
    END DO
    END DO
    END DO



    DO j = j_start, j_end
    DO i = i_start, i_end
      hatavg(i,1,j)   =  0.5 * (  &
                         cf1 * hat(i,1,j-1) +  &
                         cf2 * hat(i,2,j-1) +  &
                         cf3 * hat(i,3,j-1) +  &
                         cf1 * hat(i,1,j  ) +  &
                         cf2 * hat(i,2,j  ) +  &
                         cf3 * hat(i,3,j  ) )
      hatavg(i,kte,j) =  0.5 * (  &
                         cft1 * ( hat(i,ktes1,j-1) + hat(i,ktes1,j) ) +  &
                         cft2 * ( hat(i,ktes2,j-1) + hat(i,ktes2,j) ) )
    END DO
    END DO

    
    
    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      tmpzy       = 0.25 * (  &
                    zy(i-1,k  ,j) + zy(i,k  ,j) +  &
                    zy(i-1,k+1,j) + zy(i,k+1,j) )
      tmp1(i,k,j) = ( hatavg(i,k+1,j) - hatavg(i,k,j) ) *  &
                    0.25 * tmpzy * ( rdzw(i,k,j) + rdzw(i-1,k,j) + &
                                     rdzw(i-1,k,j-1) + rdzw(i,k,j-1) )
    END DO
    END DO
    END DO








    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      rvort(i,k,j) = rvort(i,k,j) -  &
                     mm(i,j) * (  &
                     rdy * ( hat(i,k,j) - hat(i,k,j-1) ) - tmp1(i,k,j) )
    END DO
    END DO
    END DO







     IF ( .NOT. config_flags%periodic_x .AND. i_start .EQ. ids+1 ) THEN
       DO j = jts, jte
       DO k = kts, kte
         rvort(ids,k,j) = rvort(ids+1,k,j)
       END DO
       END DO
     END IF

     IF ( .NOT. config_flags%periodic_y .AND. j_start .EQ. jds+1) THEN
       DO k = kts, kte
       DO i = its, ite
         rvort(i,k,jds) = rvort(i,k,jds+1)
       END DO
       END DO
     END IF

     IF ( .NOT. config_flags%periodic_x .AND. i_end .EQ. ide-1) THEN
       DO j = jts, jte
       DO k = kts, kte
         rvort(ide,k,j) = rvort(ide-1,k,j)
       END DO
       END DO
     END IF

     IF ( .NOT. config_flags%periodic_y .AND. j_end .EQ. jde-1) THEN
       DO k = kts, kte
       DO i = its, ite
         rvort(i,k,jde) = rvort(i,k,jde-1)
       END DO
       END DO
     END IF








    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      wavg(i,k,j) = 0.125 * (  &
                    w(i,k  ,j  ) + w(i-1,k  ,j  ) +  &
                    w(i,k  ,j-1) + w(i-1,k  ,j-1) +  &
                    w(i,k+1,j  ) + w(i-1,k+1,j  ) +  &
                    w(i,k+1,j-1) + w(i-1,k+1,j-1) )
    END DO
    END DO
    END DO








    DO j = j_start, j_end
    DO i = i_start, i_end
      use_column(i,j) = .true.
      uh(i,j) = 0.
    END DO
    END DO

    
    

    DO j = j_start, j_end
    DO k = kts, ktf
    DO i = i_start, i_end
      zl = ( 0.25 * (  &
           (( ph(i  ,k  ,j  ) + phb(i  ,k  ,j  ) ) / g - ht(i  ,j  ) ) +  &
           (( ph(i-1,k  ,j  ) + phb(i-1,k  ,j  ) ) / g - ht(i-1,j  ) ) +  &
           (( ph(i  ,k  ,j-1) + phb(i  ,k  ,j-1) ) / g - ht(i  ,j-1) ) +  &
           (( ph(i-1,k  ,j-1) + phb(i-1,k  ,j-1) ) / g - ht(i-1,j-1) ) ) )

      zu = ( 0.25 * (  &
           (( ph(i  ,k+1,j  ) + phb(i  ,k+1,j  ) ) / g - ht(i  ,j  ) ) +  &
           (( ph(i-1,k+1,j  ) + phb(i-1,k+1,j  ) ) / g - ht(i-1,j  ) ) +  &
           (( ph(i  ,k+1,j-1) + phb(i  ,k+1,j-1) ) / g - ht(i  ,j-1) ) +  &
           (( ph(i-1,k+1,j-1) + phb(i-1,k+1,j-1) ) / g - ht(i-1,j-1) ) ) )

      IF ( zl .GE. 2000. .AND. zu .LE. 5000. ) THEN
        IF ( wavg(i,k,j) .GT. 0. .AND. wavg(i,k+1,j) .GT. 0. ) THEN
          uh(i,j) = uh(i,j) + ( ( wavg(i,k,j) * rvort(i,k,j) + &
                    wavg(i,k+1,j) * rvort(i,k+1,j) ) * 0.5 ) &
                    * ( zu - zl )
        ELSE
          use_column(i,j) = .false.
          uh(i,j) = 0.
        ENDIF
      ENDIF
    END DO
    END DO
    END DO



    DO j = MAX(jds+1,jts),MIN(jde-2,jte)
    DO i = MAX(ids+1,its),MIN(ide-2,ite)
      uh_smth = 0.25   *   uh(i  ,j  ) + &
                0.125  * ( uh(i+1,j  ) + uh(i-1,j  ) + &
                           uh(i  ,j+1) + uh(i  ,j-1) ) + &
                0.0625 * ( uh(i+1,j+1) + uh(i+1,j-1) + &
                           uh(i-1,j+1) + uh(i-1,j-1) )

      IF ( use_column(i,j) ) THEN
        IF ( uh_smth .GT. up_heli_max(i,j) ) THEN
           up_heli_max(i,j) = uh_smth
        ENDIF
      ENDIF




    END DO
    END DO







    IF ( .NOT. config_flags%periodic_x .AND. i_start .EQ. ids+1 ) THEN
      DO j = jts, jte
      DO k = kts, kte

        up_heli_max(ids,j) = up_heli_max(ids+1,j)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_start .EQ. jds+1) THEN
      DO k = kts, kte
      DO i = its, ite

        up_heli_max(i,jds) = up_heli_max(i,jds+1)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_x .AND. i_end .EQ. ide-1) THEN
      DO j = jts, jte
      DO k = kts, kte

        up_heli_max(ide,j) = up_heli_max(ide-1,j)
      END DO
      END DO
    END IF

    IF ( .NOT. config_flags%periodic_y .AND. j_end .EQ. jde-1) THEN
      DO k = kts, kte
      DO i = its, ite

        up_heli_max(i,jde) = up_heli_max(i,jde-1)
      END DO
      END DO
    END IF



    END SUBROUTINE cal_helicity




    END MODULE module_diffusion_em




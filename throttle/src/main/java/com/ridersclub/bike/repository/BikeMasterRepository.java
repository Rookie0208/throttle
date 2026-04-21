package com.ridersclub.bike.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.ridersclub.bike.entity.BikeMaster;

@Repository
public interface BikeMasterRepository extends JpaRepository<BikeMaster, Long> {
    Optional<BikeMaster> findByIdAndActiveTrue(Long id);

    boolean existsByBrandIgnoreCaseAndModelIgnoreCaseAndVariantIgnoreCase(
            String brand,
            String model,
            String variant);

    @Query("""
            select distinct b.brand
            from BikeMaster b
            where b.active = true
              and (:query = '' or lower(b.brand) like lower(concat('%', :query, '%')))
            order by b.brand asc
            """)
    List<String> findBrands(@Param("query") String query);

    @Query("""
            select distinct b.model
            from BikeMaster b
            where b.active = true
              and lower(b.brand) = lower(:brand)
              and (:query = '' or lower(b.model) like lower(concat('%', :query, '%')))
            order by b.model asc
            """)
    List<String> findModels(@Param("brand") String brand, @Param("query") String query);

    @Query("""
            select b
            from BikeMaster b
            where b.active = true
              and lower(b.brand) = lower(:brand)
              and lower(b.model) = lower(:model)
              and (:query = '' or lower(b.variant) like lower(concat('%', :query, '%')))
            order by b.variant asc
            """)
    List<BikeMaster> findVariants(
            @Param("brand") String brand,
            @Param("model") String model,
            @Param("query") String query);

    @Query("""
            select b
            from BikeMaster b
            where b.active = true
              and (
                    :query = ''
                    or lower(b.brand) like lower(concat('%', :query, '%'))
                    or lower(b.model) like lower(concat('%', :query, '%'))
                    or lower(b.variant) like lower(concat('%', :query, '%'))
                  )
            order by b.brand asc, b.model asc, b.variant asc
            """)
    List<BikeMaster> searchActive(@Param("query") String query);

    @Query("""
            select b
            from BikeMaster b
            where :query = ''
               or lower(b.brand) like lower(concat('%', :query, '%'))
               or lower(b.model) like lower(concat('%', :query, '%'))
               or lower(b.variant) like lower(concat('%', :query, '%'))
            order by b.brand asc, b.model asc, b.variant asc
            """)
    List<BikeMaster> searchAll(@Param("query") String query);
}

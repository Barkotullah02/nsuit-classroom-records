package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.BlogCategory;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BlogCategoryRepository extends JpaRepository<BlogCategory, Integer> {
    Optional<BlogCategory> findByCategorySlug(String categorySlug);
}

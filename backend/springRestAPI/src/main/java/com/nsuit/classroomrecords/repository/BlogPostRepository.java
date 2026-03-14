package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.BlogPost;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BlogPostRepository extends JpaRepository<BlogPost, Integer> {
    Optional<BlogPost> findBySlug(String slug);
}

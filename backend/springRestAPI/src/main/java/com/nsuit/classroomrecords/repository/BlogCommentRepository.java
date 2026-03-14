package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.BlogComment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BlogCommentRepository extends JpaRepository<BlogComment, Integer> {
}

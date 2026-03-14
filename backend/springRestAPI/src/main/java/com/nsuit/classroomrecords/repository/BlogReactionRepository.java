package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.BlogReaction;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BlogReactionRepository extends JpaRepository<BlogReaction, Integer> {
}

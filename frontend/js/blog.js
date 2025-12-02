// Blog functionality for listing and viewing posts
let currentUser = null;
let currentPage = 1;
let currentCategory = '';
let currentSearch = '';
const postsPerPage = 5;

// Initialize based on page
document.addEventListener('DOMContentLoaded', async () => {
    currentUser = Utils.getCurrentUser();
    if (!currentUser) {
        window.location.href = 'index.html';
        return;
    }

    // Update user info in sidebar
    document.getElementById('userName').textContent = currentUser.full_name;
    document.getElementById('userRole').textContent = currentUser.role;
    document.getElementById('userAvatar').textContent = currentUser.full_name.charAt(0).toUpperCase();

    // Logout handler
    document.getElementById('logoutBtn')?.addEventListener('click', () => {
        localStorage.removeItem('jwt_token');
        localStorage.removeItem('user');
        window.location.href = 'index.html';
    });

    // Determine which page we're on
    const path = window.location.pathname;
    
    if (path.includes('blog.html')) {
        await initBlogListing();
    } else if (path.includes('blog-post.html')) {
        await initBlogPost();
    }
});

// ===== BLOG LISTING PAGE =====
async function initBlogListing() {
    // Show create post button only for admins
    if (currentUser.role === 'admin') {
        const createBtn = document.getElementById('createPostBtn');
        createBtn.style.display = 'inline-flex';
        createBtn.addEventListener('click', () => {
            window.location.href = 'blog-admin.html';
        });
    }

    // Load categories
    await loadCategories();

    // Load popular posts sidebar
    await loadPopularPosts();

    // Load initial posts
    await loadPosts();

    // Search functionality
    let searchTimeout;
    document.getElementById('searchInput').addEventListener('input', (e) => {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            currentSearch = e.target.value;
            currentPage = 1;
            loadPosts();
        }, 500);
    });

    // Category filter clicks
    document.getElementById('categoryFilter').addEventListener('click', (e) => {
        if (e.target.classList.contains('category-btn')) {
            document.querySelectorAll('.category-btn').forEach(btn => btn.classList.remove('active'));
            e.target.classList.add('active');
            currentCategory = e.target.dataset.category;
            currentPage = 1;
            loadPosts();
        }
    });
}

async function loadCategories() {
    try {
        const response = await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_CATEGORIES, 'GET');
        if (response.success) {
            const filterContainer = document.getElementById('categoryFilter');
            const statsContainer = document.getElementById('categoriesStats');
            
            response.data.forEach(cat => {
                // Add to filter buttons
                const btn = document.createElement('button');
                btn.className = 'category-btn';
                btn.dataset.category = cat.category_id;
                btn.textContent = cat.category_name;
                filterContainer.appendChild(btn);

                // Add to sidebar stats
                if (statsContainer) {
                    const div = document.createElement('div');
                    div.style.cssText = 'display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid var(--border-color);';
                    div.innerHTML = `
                        <span>${cat.category_name}</span>
                        <span style="color: var(--text-secondary);">${cat.post_count}</span>
                    `;
                    statsContainer.appendChild(div);
                }
            });
        }
    } catch (error) {
        console.error('Failed to load categories:', error);
    }
}

async function loadPosts() {
    const container = document.getElementById('postsContainer');
    container.innerHTML = '<div style="text-align: center; padding: 40px;"><div class="spinner"></div></div>';

    try {
        const offset = (currentPage - 1) * postsPerPage;
        let url = `${CONFIG.ENDPOINTS.BLOG_POSTS}?status=published&limit=${postsPerPage}&offset=${offset}`;
        
        if (currentCategory) url += `&category=${currentCategory}`;
        if (currentSearch) url += `&search=${encodeURIComponent(currentSearch)}`;

        const response = await Utils.apiRequest(url, 'GET');
        
        if (response.success) {
            const { posts, total } = response.data;
            
            if (posts.length === 0) {
                container.innerHTML = '<div class="no-posts"><i class="fas fa-inbox" style="font-size: 48px; opacity: 0.3; margin-bottom: 15px;"></i><p>No posts found</p></div>';
            } else {
                container.innerHTML = posts.map(post => createPostCard(post)).join('');
                
                // Add click handlers
                container.querySelectorAll('.post-card').forEach(card => {
                    card.addEventListener('click', () => {
                        window.location.href = `blog-post.html?id=${card.dataset.postId}`;
                    });
                });
            }

            // Update pagination
            updatePagination(total, postsPerPage);
        }
    } catch (error) {
        console.error('Failed to load posts:', error);
        container.innerHTML = '<div class="no-posts"><p>Failed to load posts. Please try again.</p></div>';
    }
}

function createPostCard(post) {
    const publishedDate = new Date(post.published_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    
    return `
        <div class="post-card" data-post-id="${post.post_id}">
            <div class="post-featured">
                ${post.featured_image ? `<img src="${post.featured_image}" alt="${post.title}">` : ''}
                <span class="post-category-badge">${post.category_name}</span>
                ${post.is_pinned ? '<span class="post-pinned-badge"><i class="fas fa-thumbtack"></i> Pinned</span>' : ''}
            </div>
            <div class="post-content">
                <h2 class="post-title">${post.title}</h2>
                <p class="post-excerpt">${post.excerpt || post.content.substring(0, 150) + '...'}</p>
                <div class="post-meta">
                    <span class="post-meta-item"><i class="fas fa-user"></i> ${post.author_name}</span>
                    <span class="post-meta-item"><i class="fas fa-calendar"></i> ${publishedDate}</span>
                    <span class="post-meta-item"><i class="fas fa-eye"></i> ${post.view_count} views</span>
                    <span class="post-meta-item"><i class="fas fa-comments"></i> ${post.comment_count}</span>
                    <span class="post-meta-item"><i class="fas fa-heart"></i> ${post.reaction_count}</span>
                </div>
            </div>
        </div>
    `;
}

async function loadPopularPosts() {
    const container = document.getElementById('popularPosts');
    
    try {
        const response = await Utils.apiRequest(`${CONFIG.ENDPOINTS.BLOG_POSTS}?status=published&popular=true&limit=5`, 'GET');
        
        if (response.success && response.data.posts.length > 0) {
            container.innerHTML = response.data.posts.map(post => `
                <div class="popular-post" onclick="window.location.href='blog-post.html?id=${post.post_id}'">
                    <div class="popular-post-title">${post.title}</div>
                    <div class="popular-post-meta">
                        <i class="fas fa-eye"></i> ${post.view_count} views
                    </div>
                </div>
            `).join('');
        } else {
            container.innerHTML = '<p style="color: var(--text-secondary); font-size: 13px;">No popular posts yet</p>';
        }
    } catch (error) {
        console.error('Failed to load popular posts:', error);
        container.innerHTML = '<p style="color: var(--text-secondary); font-size: 13px;">Failed to load</p>';
    }
}

function updatePagination(total, perPage) {
    const totalPages = Math.ceil(total / perPage);
    const pagination = document.getElementById('pagination');
    
    if (totalPages <= 1) {
        pagination.innerHTML = '';
        return;
    }

    let html = '';
    
    // Previous button
    html += `<button class="page-btn" ${currentPage === 1 ? 'disabled' : ''} onclick="changePage(${currentPage - 1})"><i class="fas fa-chevron-left"></i></button>`;
    
    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || (i >= currentPage - 1 && i <= currentPage + 1)) {
            html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" onclick="changePage(${i})">${i}</button>`;
        } else if (i === currentPage - 2 || i === currentPage + 2) {
            html += '<span style="padding: 8px;">...</span>';
        }
    }
    
    // Next button
    html += `<button class="page-btn" ${currentPage === totalPages ? 'disabled' : ''} onclick="changePage(${currentPage + 1})"><i class="fas fa-chevron-right"></i></button>`;
    
    pagination.innerHTML = html;
}

function changePage(page) {
    currentPage = page;
    loadPosts();
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ===== SINGLE POST PAGE =====
async function initBlogPost() {
    const urlParams = new URLSearchParams(window.location.search);
    const postId = urlParams.get('id');
    
    if (!postId) {
        showNotification('Invalid post ID', 'error');
        setTimeout(() => window.location.href = 'blog.html', 2000);
        return;
    }

    await loadPost(postId);
    await loadReactions(postId);
    await loadComments(postId);

    // Comment submission
    document.getElementById('submitComment').addEventListener('click', () => submitComment(postId));
}

async function loadPost(postId) {
    const container = document.getElementById('postContent');
    
    try {
        const response = await Utils.apiRequest(`${CONFIG.ENDPOINTS.BLOG_POSTS}?id=${postId}`, 'GET');
        
        if (response.success && response.data) {
            const post = response.data;
            const publishedDate = new Date(post.published_at).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
            
            container.innerHTML = `
                <div class="post-header">
                    <span class="post-category-tag">${post.category_name}</span>
                    <h1 class="post-title-main">${post.title}</h1>
                    <div class="post-meta-main">
                        <span><i class="fas fa-user"></i> ${post.author_name}</span>
                        <span><i class="fas fa-calendar"></i> ${publishedDate}</span>
                        <span><i class="fas fa-eye"></i> ${post.view_count} views</span>
                        <span><i class="fas fa-comments"></i> ${post.comment_count} comments</span>
                    </div>
                </div>
                ${post.featured_image ? `<div class="post-featured-main"><img src="${post.featured_image}" alt="${post.title}"></div>` : ''}
                <div class="post-body">${post.content.replace(/\n/g, '<br>')}</div>
            `;

            // Show admin actions if user is admin
            if (currentUser.role === 'admin') {
                const adminActions = document.getElementById('adminActions');
                adminActions.style.display = 'flex';
                adminActions.innerHTML = `
                    <button class="btn btn-secondary" onclick="window.location.href='blog-admin.html'">
                        <i class="fas fa-edit"></i> Edit Post
                    </button>
                    <button class="btn btn-danger" onclick="deletePost(${postId})">
                        <i class="fas fa-trash"></i> Delete Post
                    </button>
                `;
            }
        }
    } catch (error) {
        console.error('Failed to load post:', error);
        container.innerHTML = '<div class="no-posts"><p>Failed to load post. Please try again.</p></div>';
    }
}

async function loadReactions(postId) {
    const container = document.getElementById('reactionsSection');
    
    try {
        const response = await Utils.apiRequest(`${CONFIG.ENDPOINTS.BLOG_REACTIONS}?post_id=${postId}`, 'GET');
        
        if (response.success) {
            const reactions = response.data.reactions;
            const userReaction = response.data.user_reaction;
            
            const reactionTypes = [
                { type: 'like', icon: '👍', label: 'Like' },
                { type: 'love', icon: '❤️', label: 'Love' },
                { type: 'celebrate', icon: '🎉', label: 'Celebrate' },
                { type: 'insightful', icon: '💡', label: 'Insightful' }
            ];
            
            container.innerHTML = reactionTypes.map(r => {
                const count = reactions.find(reaction => reaction.reaction_type === r.type)?.count || 0;
                const isActive = userReaction === r.type;
                return `
                    <button class="reaction-btn ${isActive ? 'active' : ''}" onclick="toggleReaction(${postId}, '${r.type}')">
                        <span class="reaction-icon">${r.icon}</span>
                        <span>${count > 0 ? count : ''}</span>
                    </button>
                `;
            }).join('');
        }
    } catch (error) {
        console.error('Failed to load reactions:', error);
    }
}

async function toggleReaction(postId, reactionType) {
    try {
        // Check if user already has this reaction
        const currentReactions = await Utils.apiRequest(`${CONFIG.ENDPOINTS.BLOG_REACTIONS}?post_id=${postId}`, 'GET');
        
        if (currentReactions.data.user_reaction === reactionType) {
            // Remove reaction
            await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_REACTIONS, 'DELETE', { post_id: postId });
        } else {
            // Add/update reaction
            await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_REACTIONS, 'POST', { post_id: postId, reaction_type: reactionType });
        }
        
        // Reload reactions
        await loadReactions(postId);
    } catch (error) {
        console.error('Failed to toggle reaction:', error);
        showNotification('Failed to update reaction', 'error');
    }
}

async function loadComments(postId) {
    const container = document.getElementById('commentsContainer');
    
    try {
        const response = await Utils.apiRequest(`${CONFIG.ENDPOINTS.BLOG_COMMENTS}?post_id=${postId}`, 'GET');
        
        if (response.success) {
            const comments = response.data;
            
            if (comments.length === 0) {
                container.innerHTML = '<p style="text-align: center; color: var(--text-secondary); padding: 30px;">No comments yet. Be the first to comment!</p>';
            } else {
                container.innerHTML = comments.map(comment => renderComment(comment, postId)).join('');
            }
        }
    } catch (error) {
        console.error('Failed to load comments:', error);
        container.innerHTML = '<p style="text-align: center; color: var(--text-secondary);">Failed to load comments</p>';
    }
}

function renderComment(comment, postId, isReply = false) {
    const commentDate = new Date(comment.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    const canEdit = currentUser.role === 'admin' || currentUser.user_id === comment.user_id;
    
    let html = `
        <div class="comment ${isReply ? 'reply' : ''}" id="comment-${comment.comment_id}">
            <div class="comment-header">
                <span class="comment-author">${comment.user_name}</span>
                <span class="comment-date">${commentDate}</span>
            </div>
            <div class="comment-text">${comment.comment_text}</div>
            <div class="comment-actions">
                <span class="comment-action" onclick="showReplyForm(${comment.comment_id}, ${postId})">
                    <i class="fas fa-reply"></i> Reply
                </span>
                ${canEdit ? `<span class="comment-action" onclick="deleteComment(${comment.comment_id}, ${postId})"><i class="fas fa-trash"></i> Delete</span>` : ''}
            </div>
            <div class="reply-form" id="reply-form-${comment.comment_id}">
                <textarea placeholder="Write a reply..." id="reply-text-${comment.comment_id}"></textarea>
                <button class="btn btn-primary btn-sm" onclick="submitReply(${comment.comment_id}, ${postId})" style="margin-top: 10px;">Post Reply</button>
            </div>
        </div>
    `;
    
    // Add replies
    if (comment.replies && comment.replies.length > 0) {
        html += comment.replies.map(reply => renderComment(reply, postId, true)).join('');
    }
    
    return html;
}

function showReplyForm(commentId, postId) {
    const form = document.getElementById(`reply-form-${commentId}`);
    form.classList.toggle('active');
}

async function submitComment(postId) {
    const text = document.getElementById('commentText').value.trim();
    
    if (!text) {
        showNotification('Please enter a comment', 'error');
        return;
    }
    
    try {
        await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_COMMENTS, 'POST', {
            post_id: postId,
            comment_text: text
        });
        
        document.getElementById('commentText').value = '';
        showNotification('Comment posted successfully', 'success');
        await loadComments(postId);
    } catch (error) {
        console.error('Failed to post comment:', error);
        showNotification('Failed to post comment', 'error');
    }
}

async function submitReply(parentCommentId, postId) {
    const text = document.getElementById(`reply-text-${parentCommentId}`).value.trim();
    
    if (!text) {
        showNotification('Please enter a reply', 'error');
        return;
    }
    
    try {
        await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_COMMENTS, 'POST', {
            post_id: postId,
            comment_text: text,
            parent_comment_id: parentCommentId
        });
        
        document.getElementById(`reply-text-${parentCommentId}`).value = '';
        showNotification('Reply posted successfully', 'success');
        await loadComments(postId);
    } catch (error) {
        console.error('Failed to post reply:', error);
        showNotification('Failed to post reply', 'error');
    }
}

async function deleteComment(commentId, postId) {
    if (!confirm('Are you sure you want to delete this comment?')) return;
    
    try {
        await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_COMMENTS, 'DELETE', { comment_id: commentId });
        showNotification('Comment deleted successfully', 'success');
        await loadComments(postId);
    } catch (error) {
        console.error('Failed to delete comment:', error);
        showNotification('Failed to delete comment', 'error');
    }
}

async function deletePost(postId) {
    if (!confirm('Are you sure you want to delete this post? This action cannot be undone.')) return;
    
    try {
        await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_POSTS, 'DELETE', { post_id: postId });
        showNotification('Post deleted successfully', 'success');
        setTimeout(() => window.location.href = 'blog.html', 1500);
    } catch (error) {
        console.error('Failed to delete post:', error);
        showNotification('Failed to delete post', 'error');
    }
}

function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        position: fixed; top: 20px; right: 20px; padding: 15px 20px;
        background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
        color: white; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 10000; animation: slideIn 0.3s ease-out;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease-in';
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

// Blog Admin functionality for managing posts
let currentUser = null;
let categories = [];
let editingPostId = null;

document.addEventListener('DOMContentLoaded', async () => {
    currentUser = Utils.getCurrentUser();
    
    // Check if user is admin
    if (!currentUser || currentUser.role !== 'admin') {
        showNotification('Access denied. Admin only.', 'error');
        setTimeout(() => window.location.href = 'blog.html', 2000);
        return;
    }

    // Update user info in sidebar
    document.getElementById('userName').textContent = currentUser.full_name;
    document.getElementById('userRole').textContent = currentUser.role;
    document.getElementById('userAvatar').textContent = currentUser.full_name.charAt(0).toUpperCase();

    // Logout handler
    document.getElementById('logoutBtn').addEventListener('click', () => {
        localStorage.removeItem('jwt_token');
        localStorage.removeItem('user');
        window.location.href = 'index.html';
    });

    // Load categories for the form
    await loadCategories();

    // Load all posts (including drafts)
    await loadAllPosts();

    // Create post button
    document.getElementById('createPostBtn').addEventListener('click', openCreateModal);

    // Form submission
    document.getElementById('postForm').addEventListener('submit', handleFormSubmit);
});

async function loadCategories() {
    try {
        const response = await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_CATEGORIES, 'GET');
        if (response.success) {
            categories = response.data;
            const select = document.getElementById('postCategory');
            select.innerHTML = '<option value="">Select category...</option>';
            categories.forEach(cat => {
                const option = document.createElement('option');
                option.value = cat.category_id;
                option.textContent = cat.category_name;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Failed to load categories:', error);
        showNotification('Failed to load categories', 'error');
    }
}

async function loadAllPosts() {
    const container = document.getElementById('postsContainer');
    container.innerHTML = '<div style="text-align: center; padding: 40px;"><div class="spinner"></div></div>';

    try {
        // Load all posts (no status filter to include drafts)
        const response = await Utils.apiRequest(`${CONFIG.ENDPOINTS.BLOG_POSTS}?limit=100`, 'GET');
        
        if (response.success) {
            const posts = response.data.posts;
            
            if (posts.length === 0) {
                container.innerHTML = `
                    <div style="text-align: center; padding: 60px; color: var(--text-secondary);">
                        <i class="fas fa-file-alt" style="font-size: 48px; opacity: 0.3; margin-bottom: 15px;"></i>
                        <p>No posts yet. Create your first post!</p>
                    </div>
                `;
            } else {
                container.innerHTML = posts.map(post => createPostItem(post)).join('');
            }
        }
    } catch (error) {
        console.error('Failed to load posts:', error);
        container.innerHTML = '<div style="text-align: center; padding: 40px; color: var(--text-secondary);">Failed to load posts</div>';
    }
}

function createPostItem(post) {
    const publishedDate = post.published_at 
        ? new Date(post.published_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
        : 'Not published';
    
    return `
        <div class="post-item">
            <div class="post-info">
                <div class="post-info-title">
                    ${post.title}
                    ${post.is_pinned ? '<i class="fas fa-thumbtack" style="color: #f59e0b; margin-left: 8px;"></i>' : ''}
                </div>
                <div class="post-info-meta">
                    <span class="status-badge status-${post.status}">${post.status.toUpperCase()}</span>
                    <span><i class="fas fa-tag"></i> ${post.category_name}</span>
                    <span><i class="fas fa-calendar"></i> ${publishedDate}</span>
                    <span><i class="fas fa-eye"></i> ${post.view_count} views</span>
                    <span><i class="fas fa-comments"></i> ${post.comment_count} comments</span>
                    <span><i class="fas fa-heart"></i> ${post.reaction_count} reactions</span>
                </div>
            </div>
            <div class="post-actions">
                <button class="btn btn-sm btn-secondary" onclick="editPost(${post.post_id})">
                    <i class="fas fa-edit"></i> Edit
                </button>
                <button class="btn btn-sm btn-primary" onclick="window.open('blog-post.html?id=${post.post_id}', '_blank')">
                    <i class="fas fa-eye"></i> View
                </button>
                <button class="btn btn-sm btn-danger" onclick="deletePost(${post.post_id})">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </div>
        </div>
    `;
}

function openCreateModal() {
    editingPostId = null;
    document.getElementById('modalTitle').textContent = 'Create New Post';
    document.getElementById('submitBtnText').textContent = 'Create Post';
    document.getElementById('postForm').reset();
    document.getElementById('postId').value = '';
    removeImage(); // Clear any image preview
    document.getElementById('postModal').classList.add('active');
}

async function editPost(postId) {
    editingPostId = postId;
    document.getElementById('modalTitle').textContent = 'Edit Post';
    document.getElementById('submitBtnText').textContent = 'Update Post';
    
    try {
        const response = await Utils.apiRequest(`${CONFIG.ENDPOINTS.BLOG_POSTS}?id=${postId}`, 'GET');
        
        if (response.success && response.data) {
            const post = response.data;
            document.getElementById('postId').value = post.post_id;
            document.getElementById('postTitle').value = post.title;
            document.getElementById('postCategory').value = post.category_id;
            document.getElementById('postStatus').value = post.status;
            document.getElementById('postExcerpt').value = post.excerpt || '';
            document.getElementById('postContent').value = post.content;
            document.getElementById('postPinned').checked = post.is_pinned == 1;
            
            // Handle existing featured image
            if (post.featured_image) {
                const preview = document.getElementById('imagePreview');
                const removeBtn = document.querySelector('.remove-image');
                const imageData = document.getElementById('postImageData');
                
                preview.src = post.featured_image;
                preview.classList.add('show');
                removeBtn.classList.add('show');
                imageData.value = post.featured_image;
            } else {
                removeImage();
            }
            
            document.getElementById('postModal').classList.add('active');
        }
    } catch (error) {
        console.error('Failed to load post:', error);
        showNotification('Failed to load post details', 'error');
    }
}

async function handleFormSubmit(e) {
    e.preventDefault();
    
    const postId = document.getElementById('postId').value;
    const imageData = document.getElementById('postImageData').value; // Get base64 image data
    
    const formData = {
        title: document.getElementById('postTitle').value.trim(),
        category_id: document.getElementById('postCategory').value,
        status: document.getElementById('postStatus').value,
        excerpt: document.getElementById('postExcerpt').value.trim(),
        content: document.getElementById('postContent').value.trim(),
        featured_image: imageData || null, // Use base64 data
        is_pinned: document.getElementById('postPinned').checked ? 1 : 0
    };

    // Validation
    if (!formData.title || !formData.category_id || !formData.content) {
        showNotification('Please fill in all required fields', 'error');
        return;
    }

    try {
        let response;
        if (postId) {
            // Update existing post
            formData.post_id = postId;
            response = await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_POSTS, 'PUT', formData);
        } else {
            // Create new post
            response = await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_POSTS, 'POST', formData);
        }

        console.log('API Response:', response);

        if (response && response.success) {
            showNotification(postId ? 'Post updated successfully' : 'Post created successfully', 'success');
            closePostModal();
            await loadAllPosts();
        } else {
            showNotification(response?.message || 'Failed to save post', 'error');
        }
    } catch (error) {
        console.error('Failed to save post:', error);
        showNotification(error.message || 'Failed to save post. Please try again.', 'error');
    }
}

async function deletePost(postId) {
    if (!confirm('Are you sure you want to delete this post? This will also delete all comments and reactions. This action cannot be undone.')) {
        return;
    }

    try {
        const response = await Utils.apiRequest(CONFIG.ENDPOINTS.BLOG_POSTS, 'DELETE', { post_id: postId });
        
        if (response.success) {
            showNotification('Post deleted successfully', 'success');
            await loadAllPosts();
        }
    } catch (error) {
        console.error('Failed to delete post:', error);
        showNotification('Failed to delete post', 'error');
    }
}

function closePostModal() {
    document.getElementById('postModal').classList.remove('active');
    document.getElementById('postForm').reset();
    removeImage(); // Clear image preview
    editingPostId = null;
}

// Close modal when clicking outside
document.addEventListener('click', (e) => {
    const modal = document.getElementById('postModal');
    if (e.target === modal) {
        closePostModal();
    }
});

// Text formatting functions - WYSIWYG style (like MS Word)
function formatText(textareaId, format) {
    const textarea = document.getElementById(textareaId);
    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const selectedText = textarea.value.substring(start, end);
    
    if (!selectedText && format !== 'link') {
        alert('Please select text to format');
        return;
    }
    
    let replacement = '';
    let cursorOffset = 0;
    
    switch(format) {
        case 'bold':
            replacement = `<strong>${selectedText}</strong>`;
            cursorOffset = 8; // length of <strong>
            break;
        case 'italic':
            replacement = `<em>${selectedText}</em>`;
            cursorOffset = 4; // length of <em>
            break;
        case 'underline':
            replacement = `<u>${selectedText}</u>`;
            cursorOffset = 3; // length of <u>
            break;
        case 'h1':
            replacement = `<h1>${selectedText}</h1>`;
            cursorOffset = 4;
            break;
        case 'h2':
            replacement = `<h2>${selectedText}</h2>`;
            cursorOffset = 4;
            break;
        case 'h3':
            replacement = `<h3>${selectedText}</h3>`;
            cursorOffset = 4;
            break;
        case 'ul':
            const ulLines = selectedText.split('\n').filter(l => l.trim());
            replacement = '<ul>\n' + ulLines.map(line => `  <li>${line.trim()}</li>`).join('\n') + '\n</ul>';
            cursorOffset = 5;
            break;
        case 'ol':
            const olLines = selectedText.split('\n').filter(l => l.trim());
            replacement = '<ol>\n' + olLines.map(line => `  <li>${line.trim()}</li>`).join('\n') + '\n</ol>';
            cursorOffset = 5;
            break;
        case 'link':
            const url = prompt('Enter URL:', 'https://');
            if (url) {
                replacement = `<a href="${url}" target="_blank">${selectedText || url}</a>`;
                cursorOffset = 9 + url.length;
            } else {
                return;
            }
            break;
        case 'quote':
            replacement = `<blockquote>${selectedText}</blockquote>`;
            cursorOffset = 12;
            break;
        default:
            return;
    }
    
    // Replace selected text
    const newValue = textarea.value.substring(0, start) + replacement + textarea.value.substring(end);
    textarea.value = newValue;
    
    // Set cursor position after the opening tag
    textarea.focus();
    textarea.setSelectionRange(start + cursorOffset, start + cursorOffset + selectedText.length);
}

// Image preview and handling
function previewImage(input) {
    const preview = document.getElementById('imagePreview');
    const removeBtn = document.querySelector('.remove-image');
    const imageData = document.getElementById('postImageData');
    
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        
        reader.onload = function(e) {
            preview.src = e.target.result;
            preview.classList.add('show');
            removeBtn.classList.add('show');
            imageData.value = e.target.result; // Store base64 data
        };
        
        reader.readAsDataURL(input.files[0]);
    }
}

function removeImage() {
    const input = document.getElementById('postImage');
    const preview = document.getElementById('imagePreview');
    const removeBtn = document.querySelector('.remove-image');
    const imageData = document.getElementById('postImageData');
    
    input.value = '';
    preview.src = '';
    preview.classList.remove('show');
    removeBtn.classList.remove('show');
    imageData.value = '';
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

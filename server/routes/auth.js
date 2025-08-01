const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { upload } = require('../services/cloudinary');
const {
    register,
    login,
    logout,
    getCurrentUser,
    forgotPassword,
    resetPassword,
    resendVerification
} = require('../controllers/auth');

const router = express.Router();

// Routes
router.post('/register', upload.single('profileImage'), register);
router.post('/resend-verification', resendVerification);
router.post('/login', login);

router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

router.post('/logout', authMiddleware, logout);
router.get('/me', authMiddleware, getCurrentUser);

module.exports = router;
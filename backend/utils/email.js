const nodemailer = require('nodemailer');

// Create email transporter
const createTransporter = () => {
  return nodemailer.createTransporter({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT) || 587,
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

// Send password reset email
const sendPasswordResetEmail = async (email, resetToken, userName) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn('Email configuration not set up. Skipping password reset email.');
    return;
  }

  try {
    const transporter = createTransporter();
    
    const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;
    
    const mailOptions = {
      from: process.env.EMAIL_FROM || 'SyncN App <noreply@syncnapp.com>',
      to: email,
      subject: 'Reset Your SyncN Password',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #8B5CF6;">SyncN Password Reset</h2>
          <p>Hi ${userName},</p>
          <p>We received a request to reset your password for your SyncN account.</p>
          <p>Click the button below to reset your password:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetUrl}" 
               style="background-color: #8B5CF6; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
              Reset Password
            </a>
          </div>
          <p>Or copy and paste this link into your browser:</p>
          <p style="word-break: break-all; color: #666;">${resetUrl}</p>
          <p><strong>This link will expire in 1 hour.</strong></p>
          <p>If you didn't request this password reset, please ignore this email.</p>
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #666; font-size: 12px;">
            This email was sent by SyncN. If you have any questions, please contact our support team.
          </p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log('✅ Password reset email sent to:', email);
    
  } catch (error) {
    console.error('❌ Failed to send password reset email:', error);
    throw error;
  }
};

// Send email verification email
const sendVerificationEmail = async (email, verificationToken) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn('Email configuration not set up. Skipping verification email.');
    return;
  }

  try {
    const transporter = createTransporter();
    
    const verificationUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/verify-email?token=${verificationToken}`;
    
    const mailOptions = {
      from: process.env.EMAIL_FROM || 'SyncN App <noreply@syncnapp.com>',
      to: email,
      subject: 'Verify Your SyncN Account',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #8B5CF6;">Welcome to SyncN!</h2>
          <p>Thank you for creating your SyncN account.</p>
          <p>Please verify your email address by clicking the button below:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${verificationUrl}" 
               style="background-color: #8B5CF6; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
              Verify Email
            </a>
          </div>
          <p>Or copy and paste this link into your browser:</p>
          <p style="word-break: break-all; color: #666;">${verificationUrl}</p>
          <p>Once verified, you'll have full access to all SyncN features.</p>
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #666; font-size: 12px;">
            This email was sent by SyncN. If you didn't create an account, please ignore this email.
          </p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log('✅ Verification email sent to:', email);
    
  } catch (error) {
    console.error('❌ Failed to send verification email:', error);
    throw error;
  }
};

// Send welcome email
const sendWelcomeEmail = async (email, userName) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn('Email configuration not set up. Skipping welcome email.');
    return;
  }

  try {
    const transporter = createTransporter();
    
    const mailOptions = {
      from: process.env.EMAIL_FROM || 'SyncN App <noreply@syncnapp.com>',
      to: email,
      subject: 'Welcome to SyncN! 🌙',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #8B5CF6;">Welcome to SyncN, ${userName}! 🌙</h2>
          <p>We're excited to have you join our community of women who are taking control of their health and fitness.</p>
          
          <h3 style="color: #8B5CF6;">What's Next?</h3>
          <ul>
            <li>📅 Complete your cycle tracking setup</li>
            <li>💪 Create your personalized fitness plan</li>
            <li>🥗 Set up your nutrition preferences</li>
            <li>📱 Download the SyncN mobile app</li>
          </ul>
          
          <p>Your journey to better health starts now. We're here to support you every step of the way!</p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/dashboard" 
               style="background-color: #8B5CF6; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
              Get Started
            </a>
          </div>
          
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #666; font-size: 12px;">
            Questions? Reply to this email or contact our support team.
          </p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log('✅ Welcome email sent to:', email);
    
  } catch (error) {
    console.error('❌ Failed to send welcome email:', error);
    throw error;
  }
};

module.exports = {
  sendPasswordResetEmail,
  sendVerificationEmail,
  sendWelcomeEmail
};

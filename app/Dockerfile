# Use official Node.js image as base image
FROM node:14

# Set the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json /app
RUN npm install

# Copy the rest of the application files
COPY . /app

# Expose the port the app will run on
EXPOSE 3000

# Run the app
CMD ["npm", "start"]

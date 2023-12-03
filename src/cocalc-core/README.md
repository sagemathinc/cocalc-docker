This is a multistage build of cocalc, which is suitable to be copied from /cocalc to be used in other containers.  It should get build with both an x86 and arm versions and tagged with the cocalc git commit that was used in the build.  

We can use this for

- the cocalc\-docker main images
- building static, hub, and project parts of cocalc much more quickly

We do NOT include nodejs \(nvm\) in here, but if you're going to use this, be careful that you're using a compatible version of nodejs.


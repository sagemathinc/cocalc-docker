I found these in an ancient Dockerfile for building Sage.  I recently
learned about the much bigger

https://github.com/sagemath/sage/blob/develop/docker/Dockerfile

and may do something new based on this.

Another issue is that on some architectures some packages in Sage
are difficult to build.  An example is Tachyon.   This is why
they are apt-get install'd earlier in the Dockerfile.
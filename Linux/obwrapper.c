// This file contains wrappers for system-library functions needed by Oberon
// It ensures Oberon is runnable on all Linux versions.

#include <pthread.h>
#include <stdio.h>

void testfunction()
{
	printf("TestFUNCTION\n");
}

int th_mutex_init(void* mutex, const void* mutexattr)
{
	return pthread_mutex_init(mutex, mutexattr);
}

int th_mutex_lock(void* mutex)
{
	return pthread_mutex_lock(mutex);
}

int th_mutex_unlock(void* mutex)
{
	return pthread_mutex_unlock(mutex);
}

int th_create(pthread_t* thread, pthread_attr_t* attr, void* (*start_routine)(void *), void* arg)
{
	return pthread_create(thread, attr, start_routine, arg);
}

int th_detach(pthread_t thread)
{
	return pthread_detach(thread);
}

int th_join(pthread_t thread, void** thread_return)
{
	return pthread_join(thread, thread_return);
}

void th_exit(void* retval)
{
	pthread_exit(retval);
}

void th_kill(pthread_t thread, int signo)
{
	pthread_kill(thread, signo);
}

pthread_t th_self()
{
	return pthread_self();
}

int th_cancel(pthread_t thread)
{
	return pthread_cancel(thread);
}

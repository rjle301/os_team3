
build/user/user:     file format elf32-i386


Disassembly of section .text:

00030000 <_start>:
   30000:	12 01                	adc    (%ecx),%al
   30002:	03 00                	add    (%eax),%eax
   30004:	5b                   	pop    %ebx
   30005:	2a 03                	sub    (%ebx),%al
	...

00030008 <process>:
**
** @param[in] ix  index of the spawn table entry to be used
*/

static void process( int ix )
{
   30008:	55                   	push   %ebp
   30009:	89 e5                	mov    %esp,%ebp
   3000b:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char buf[128];

	if( ix < 0 || ix >= IN_ENTRIES ) {
   30011:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   30015:	78 08                	js     3001f <process+0x17>
   30017:	8b 45 08             	mov    0x8(%ebp),%eax
   3001a:	83 f8 0d             	cmp    $0xd,%eax
   3001d:	76 31                	jbe    30050 <process+0x48>
		sprint( buf, "INIT: process(%d)???\n", ix );
   3001f:	83 ec 04             	sub    $0x4,%esp
   30022:	ff 75 08             	push   0x8(%ebp)
   30025:	68 48 41 03 00       	push   $0x34148
   3002a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   30030:	50                   	push   %eax
   30031:	e8 9b 2a 00 00       	call   32ad1 <sprint>
   30036:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   30039:	83 ec 0c             	sub    $0xc,%esp
   3003c:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   30042:	50                   	push   %eax
   30043:	e8 0a 29 00 00       	call   32952 <cwrites>
   30048:	83 c4 10             	add    $0x10,%esp
   3004b:	e9 c0 00 00 00       	jmp    30110 <process+0x108>
		return;
	}

	// pointer to the selected entry
	const proc_t *proc = &in_procs[ix];
   30050:	8b 55 08             	mov    0x8(%ebp),%edx
   30053:	89 d0                	mov    %edx,%eax
   30055:	01 c0                	add    %eax,%eax
   30057:	01 d0                	add    %edx,%eax
   30059:	c1 e0 02             	shl    $0x2,%eax
   3005c:	05 a0 40 03 00       	add    $0x340a0,%eax
   30061:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// kick off the process
	pid_t p = fork( proc->priority );
   30064:	8b 45 f4             	mov    -0xc(%ebp),%eax
   30067:	0f b6 40 08          	movzbl 0x8(%eax),%eax
   3006b:	0f b6 c0             	movzbl %al,%eax
   3006e:	83 ec 0c             	sub    $0xc,%esp
   30071:	50                   	push   %eax
   30072:	e8 9c 29 00 00       	call   32a13 <fork>
   30077:	83 c4 10             	add    $0x10,%esp
   3007a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if( p < 0 ) {
   3007d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   30081:	79 31                	jns    300b4 <process+0xac>

		// error!
		sprint( buf, "INIT: fork for 0x%08x failed\n",
				(uint32_t) (proc->entry) );
   30083:	8b 45 f4             	mov    -0xc(%ebp),%eax
   30086:	8b 00                	mov    (%eax),%eax
		sprint( buf, "INIT: fork for 0x%08x failed\n",
   30088:	83 ec 04             	sub    $0x4,%esp
   3008b:	50                   	push   %eax
   3008c:	68 5e 41 03 00       	push   $0x3415e
   30091:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   30097:	50                   	push   %eax
   30098:	e8 34 2a 00 00       	call   32ad1 <sprint>
   3009d:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   300a0:	83 ec 0c             	sub    $0xc,%esp
   300a3:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   300a9:	50                   	push   %eax
   300aa:	e8 a3 28 00 00       	call   32952 <cwrites>
   300af:	83 c4 10             	add    $0x10,%esp
   300b2:	eb 5c                	jmp    30110 <process+0x108>

	} else if( p == 0 ) {
   300b4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   300b8:	75 49                	jne    30103 <process+0xfb>

		// send it on its way
		exec( proc->entry, proc->args );
   300ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
   300bd:	8b 50 04             	mov    0x4(%eax),%edx
   300c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   300c3:	8b 00                	mov    (%eax),%eax
   300c5:	83 ec 08             	sub    $0x8,%esp
   300c8:	52                   	push   %edx
   300c9:	50                   	push   %eax
   300ca:	e8 4c 29 00 00       	call   32a1b <exec>
   300cf:	83 c4 10             	add    $0x10,%esp

		// uh-oh - should never get here!
		sprint( buf, "INIT: exec(0x%08x) failed\n",
				(uint32_t) (proc->entry) );
   300d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   300d5:	8b 00                	mov    (%eax),%eax
		sprint( buf, "INIT: exec(0x%08x) failed\n",
   300d7:	83 ec 04             	sub    $0x4,%esp
   300da:	50                   	push   %eax
   300db:	68 7c 41 03 00       	push   $0x3417c
   300e0:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   300e6:	50                   	push   %eax
   300e7:	e8 e5 29 00 00       	call   32ad1 <sprint>
   300ec:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   300ef:	83 ec 0c             	sub    $0xc,%esp
   300f2:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   300f8:	50                   	push   %eax
   300f9:	e8 54 28 00 00       	call   32952 <cwrites>
   300fe:	83 c4 10             	add    $0x10,%esp
   30101:	eb 0d                	jmp    30110 <process+0x108>
		// parent just reports that another one was started
		// sprint( buf, " %c(%d) ", ch, p );
		// swrites( buf );

		// remember the pid for later
		proc_pids[ix] = p;
   30103:	8b 45 08             	mov    0x8(%ebp),%eax
   30106:	8b 55 f0             	mov    -0x10(%ebp),%edx
   30109:	89 14 85 00 60 03 00 	mov    %edx,0x36000(,%eax,4)

	}
}
   30110:	c9                   	leave  
   30111:	c3                   	ret    

00030112 <init>:
/*
** The initial user process. Should be invoked with zero or one
** argument; if provided, the first argument should be the ASCII
** character 'init' will print to indicate the spawning of a process.
*/
USERMAIN( init ) {
   30112:	55                   	push   %ebp
   30113:	89 e5                	mov    %esp,%ebp
   30115:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char buf[128];
	// char ch = '+';

	ARG_PROC( 2, args, 5, argc, "init" );
   3011b:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   30122:	00 00 00 
   30125:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   3012c:	00 00 00 
   3012f:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
   30136:	00 00 00 
   30139:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
   30140:	00 00 00 
   30143:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
   3014a:	00 00 00 
   3014d:	83 ec 0c             	sub    $0xc,%esp
   30150:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   30156:	50                   	push   %eax
   30157:	6a 05                	push   $0x5
   30159:	6a 0d                	push   $0xd
   3015b:	ff 75 08             	push   0x8(%ebp)
   3015e:	6a 02                	push   $0x2
   30160:	e8 5a 25 00 00       	call   326bf <parseArgs>
   30165:	83 c4 20             	add    $0x20,%esp
   30168:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if( argc == 2 ) {
   3016b:	83 7d ec 02          	cmpl   $0x2,-0x14(%ebp)
   3016f:	75 0e                	jne    3017f <init+0x6d>
		ch = argv[1][0];
   30171:	8b 85 58 ff ff ff    	mov    -0xa8(%ebp),%eax
   30177:	0f b6 00             	movzbl (%eax),%eax
   3017a:	a2 00 50 03 00       	mov    %al,0x35000
	}

	// test the sio
	// "I hear, I see, I learn"
	swrites( "\n\nAudio, video, disco!\n\n\r" );
   3017f:	83 ec 0c             	sub    $0xc,%esp
   30182:	68 97 41 03 00       	push   $0x34197
   30187:	e8 2f 28 00 00       	call   329bb <swrites>
   3018c:	83 c4 10             	add    $0x10,%esp

	/*
	** Start all the user processes
	*/

	sprint( buf, "%s: starting user processes\n", argv[0] );
   3018f:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
   30195:	83 ec 04             	sub    $0x4,%esp
   30198:	50                   	push   %eax
   30199:	68 b1 41 03 00       	push   $0x341b1
   3019e:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   301a4:	50                   	push   %eax
   301a5:	e8 27 29 00 00       	call   32ad1 <sprint>
   301aa:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   301ad:	83 ec 0c             	sub    $0xc,%esp
   301b0:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   301b6:	50                   	push   %eax
   301b7:	e8 96 27 00 00       	call   32952 <cwrites>
   301bc:	83 c4 10             	add    $0x10,%esp

	for( int ix = 0; ix < IN_ENTRIES; ++ix ) {
   301bf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   301c6:	eb 12                	jmp    301da <init+0xc8>
		// sprint( buf, "init: starting %08x\n", in_procs[ix].entry );
		// cwrites( buf );
		process( ix );
   301c8:	83 ec 0c             	sub    $0xc,%esp
   301cb:	ff 75 f4             	push   -0xc(%ebp)
   301ce:	e8 35 fe ff ff       	call   30008 <process>
   301d3:	83 c4 10             	add    $0x10,%esp
	for( int ix = 0; ix < IN_ENTRIES; ++ix ) {
   301d6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   301da:	8b 45 f4             	mov    -0xc(%ebp),%eax
   301dd:	83 f8 0d             	cmp    $0xd,%eax
   301e0:	76 e6                	jbe    301c8 <init+0xb6>
	}

	swrites( " !!!\r\n\n" );
   301e2:	83 ec 0c             	sub    $0xc,%esp
   301e5:	68 ce 41 03 00       	push   $0x341ce
   301ea:	e8 cc 27 00 00       	call   329bb <swrites>
   301ef:	83 c4 10             	add    $0x10,%esp
	/*
	** At this point, we go into an infinite loop waiting
	** for our children (direct, or inherited) to exit.
	*/

	sprint( buf, "%s: transitioning to wait() mode\n", argv[0] );
   301f2:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
   301f8:	83 ec 04             	sub    $0x4,%esp
   301fb:	50                   	push   %eax
   301fc:	68 d8 41 03 00       	push   $0x341d8
   30201:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   30207:	50                   	push   %eax
   30208:	e8 c4 28 00 00       	call   32ad1 <sprint>
   3020d:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   30210:	83 ec 0c             	sub    $0xc,%esp
   30213:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   30219:	50                   	push   %eax
   3021a:	e8 33 27 00 00       	call   32952 <cwrites>
   3021f:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		int32_t status;
		pid_t whom = wait( &status );
   30222:	83 ec 0c             	sub    $0xc,%esp
   30225:	8d 85 50 ff ff ff    	lea    -0xb0(%ebp),%eax
   3022b:	50                   	push   %eax
   3022c:	e8 da 27 00 00       	call   32a0b <wait>
   30231:	83 c4 10             	add    $0x10,%esp
   30234:	89 45 e8             	mov    %eax,-0x18(%ebp)

		// PIDs must be positive numbers!
		if( whom <= 0 ) {
   30237:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   3023b:	7f 32                	jg     3026f <init+0x15d>

			sprint( buf, "%s: wait() returned %d???\n", argv[0], whom );
   3023d:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
   30243:	ff 75 e8             	push   -0x18(%ebp)
   30246:	50                   	push   %eax
   30247:	68 fa 41 03 00       	push   $0x341fa
   3024c:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   30252:	50                   	push   %eax
   30253:	e8 79 28 00 00       	call   32ad1 <sprint>
   30258:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   3025b:	83 ec 0c             	sub    $0xc,%esp
   3025e:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   30264:	50                   	push   %eax
   30265:	e8 e8 26 00 00       	call   32952 <cwrites>
   3026a:	83 c4 10             	add    $0x10,%esp
   3026d:	eb b3                	jmp    30222 <init+0x110>

		} else {

			// got one; report it
			sprint( buf, "%s: pid %d exit(%d)\n", argv[0], whom, status );
   3026f:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
   30275:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
   3027b:	83 ec 0c             	sub    $0xc,%esp
   3027e:	52                   	push   %edx
   3027f:	ff 75 e8             	push   -0x18(%ebp)
   30282:	50                   	push   %eax
   30283:	68 15 42 03 00       	push   $0x34215
   30288:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   3028e:	50                   	push   %eax
   3028f:	e8 3d 28 00 00       	call   32ad1 <sprint>
   30294:	83 c4 20             	add    $0x20,%esp
			cwrites( buf );
   30297:	83 ec 0c             	sub    $0xc,%esp
   3029a:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
   302a0:	50                   	push   %eax
   302a1:	e8 ac 26 00 00       	call   32952 <cwrites>
   302a6:	83 c4 10             	add    $0x10,%esp

			// figure out if this is one of ours
			for( int ix = 0; ix < IN_ENTRIES; ++ix ) {
   302a9:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   302b0:	eb 36                	jmp    302e8 <init+0x1d6>
				if( proc_pids[ix] == whom ) {
   302b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
   302b5:	8b 04 85 00 60 03 00 	mov    0x36000(,%eax,4),%eax
   302bc:	39 45 e8             	cmp    %eax,-0x18(%ebp)
   302bf:	75 23                	jne    302e4 <init+0x1d2>
					// one of ours - reset the PID field
					// (in case a respawn attempt fails)
					proc_pids[ix] = 0;
   302c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   302c4:	c7 04 85 00 60 03 00 	movl   $0x0,0x36000(,%eax,4)
   302cb:	00 00 00 00 
					/*
					** If this was idle, or if this was the shell,
					** restart it. Idle is always entry #0; if we're
					** using the shell it will be entry #1.
					*/
					if( ix == 0
   302cf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   302d3:	75 20                	jne    302f5 <init+0x1e3>
#ifdef RUN_SHELL
						|| ix == 1
#endif
							) {   // idle
						// restart this process
						process( 0 );
   302d5:	83 ec 0c             	sub    $0xc,%esp
   302d8:	6a 00                	push   $0x0
   302da:	e8 29 fd ff ff       	call   30008 <process>
   302df:	83 c4 10             	add    $0x10,%esp
					}
					break;
   302e2:	eb 11                	jmp    302f5 <init+0x1e3>
			for( int ix = 0; ix < IN_ENTRIES; ++ix ) {
   302e4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   302e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   302eb:	83 f8 0d             	cmp    $0xd,%eax
   302ee:	76 c2                	jbe    302b2 <init+0x1a0>
   302f0:	e9 2d ff ff ff       	jmp    30222 <init+0x110>
					break;
   302f5:	90                   	nop
	for(;;) {
   302f6:	e9 27 ff ff ff       	jmp    30222 <init+0x110>

000302fb <idle>:
** Compile-time options - define in Make.mk
**
**    VERBOSE_IDLE   Causes 'idle' to print '.' characters periodically
*/

USERMAIN( idle ) {
   302fb:	55                   	push   %ebp
   302fc:	89 e5                	mov    %esp,%ebp
   302fe:	81 ec 98 00 00 00    	sub    $0x98,%esp
#ifdef VERBOSE_IDLE
	// this is the character we will repeatedly print
	char ch = '.';
   30304:	c6 45 ea 2e          	movb   $0x2e,-0x16(%ebp)

	// ignore the command-line arguments
	(void) args;

	// get some current information
	pid_t pid = getpid();
   30308:	e8 2e 27 00 00       	call   32a3b <getpid>
   3030d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	time_t now = gettime();
   30310:	e8 2e 27 00 00       	call   32a43 <gettime>
   30315:	89 45 ec             	mov    %eax,-0x14(%ebp)
	prio_t prio = getprio( 0 );
   30318:	83 ec 0c             	sub    $0xc,%esp
   3031b:	6a 00                	push   $0x0
   3031d:	e8 29 27 00 00       	call   32a4b <getprio>
   30322:	83 c4 10             	add    $0x10,%esp
   30325:	88 45 eb             	mov    %al,-0x15(%ebp)

	char buf[128];
	sprint( buf, "idle [%d], started @ %u\n", pid, prio, now );
   30328:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   3032c:	83 ec 0c             	sub    $0xc,%esp
   3032f:	ff 75 ec             	push   -0x14(%ebp)
   30332:	50                   	push   %eax
   30333:	ff 75 f0             	push   -0x10(%ebp)
   30336:	68 2a 42 03 00       	push   $0x3422a
   3033b:	8d 85 6a ff ff ff    	lea    -0x96(%ebp),%eax
   30341:	50                   	push   %eax
   30342:	e8 8a 27 00 00       	call   32ad1 <sprint>
   30347:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   3034a:	83 ec 0c             	sub    $0xc,%esp
   3034d:	8d 85 6a ff ff ff    	lea    -0x96(%ebp),%eax
   30353:	50                   	push   %eax
   30354:	e8 f9 25 00 00       	call   32952 <cwrites>
   30359:	83 c4 10             	add    $0x10,%esp
	
#ifdef VERBOSE_IDLE
	write( CHAN_SIO, &ch, 1 );
   3035c:	83 ec 04             	sub    $0x4,%esp
   3035f:	6a 01                	push   $0x1
   30361:	8d 45 ea             	lea    -0x16(%ebp),%eax
   30364:	50                   	push   %eax
   30365:	6a 01                	push   $0x1
   30367:	e8 bf 26 00 00       	call   32a2b <write>
   3036c:	83 c4 10             	add    $0x10,%esp

	// idle() should never block - it must always be available
	// for dispatching when we need to pick a new current process

	for(;;) {
		DELAY(LONG);
   3036f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   30376:	eb 04                	jmp    3037c <idle+0x81>
   30378:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   3037c:	81 7d f4 ff e0 f5 05 	cmpl   $0x5f5e0ff,-0xc(%ebp)
   30383:	7e f3                	jle    30378 <idle+0x7d>
#ifdef VERBOSE_IDLE
		write( CHAN_SIO, &ch, 1 );
   30385:	83 ec 04             	sub    $0x4,%esp
   30388:	6a 01                	push   $0x1
   3038a:	8d 45 ea             	lea    -0x16(%ebp),%eax
   3038d:	50                   	push   %eax
   3038e:	6a 01                	push   $0x1
   30390:	e8 96 26 00 00       	call   32a2b <write>
   30395:	83 c4 10             	add    $0x10,%esp
		DELAY(LONG);
   30398:	eb d5                	jmp    3036f <idle+0x74>

0003039a <progABC>:
**	 where X varies depending on which "user program" this is (A, B, C)
**	       x is the ID character
**		   n is the iteration count
*/

USERMAIN( progABC ) {
   3039a:	55                   	push   %ebp
   3039b:	89 e5                	mov    %esp,%ebp
   3039d:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	int count = 30; // default iteration count
   303a3:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '1';	// default character to print
   303aa:	c6 45 f3 31          	movb   $0x31,-0xd(%ebp)
	char buf[128];	// local char buffer

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progABC" );
   303ae:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   303b5:	00 00 00 
   303b8:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   303bf:	00 00 00 
   303c2:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   303c9:	00 00 00 
   303cc:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   303d3:	00 00 00 
   303d6:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   303dd:	00 00 00 
   303e0:	83 ec 0c             	sub    $0xc,%esp
   303e3:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   303e9:	50                   	push   %eax
   303ea:	6a 05                	push   $0x5
   303ec:	6a 0d                	push   $0xd
   303ee:	ff 75 08             	push   0x8(%ebp)
   303f1:	6a 03                	push   $0x3
   303f3:	e8 c7 22 00 00       	call   326bf <parseArgs>
   303f8:	83 c4 20             	add    $0x20,%esp
   303fb:	89 45 e0             	mov    %eax,-0x20(%ebp)

	switch( argc ) {
   303fe:	83 7d e0 02          	cmpl   $0x2,-0x20(%ebp)
   30402:	74 1d                	je     30421 <progABC+0x87>
   30404:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
   30408:	75 28                	jne    30432 <progABC+0x98>
	case 3:	count = str2int( argv[2], 10 );
   3040a:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   30410:	83 ec 08             	sub    $0x8,%esp
   30413:	6a 0a                	push   $0xa
   30415:	50                   	push   %eax
   30416:	e8 2b 29 00 00       	call   32d46 <str2int>
   3041b:	83 c4 10             	add    $0x10,%esp
   3041e:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   30421:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   30427:	0f b6 00             	movzbl (%eax),%eax
   3042a:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   3042d:	e9 9e 00 00 00       	jmp    304d0 <progABC+0x136>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   30432:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   30438:	ff 75 e0             	push   -0x20(%ebp)
   3043b:	50                   	push   %eax
   3043c:	68 44 42 03 00       	push   $0x34244
   30441:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30447:	50                   	push   %eax
   30448:	e8 84 26 00 00       	call   32ad1 <sprint>
   3044d:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   30450:	83 ec 0c             	sub    $0xc,%esp
   30453:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30459:	50                   	push   %eax
   3045a:	e8 f3 24 00 00       	call   32952 <cwrites>
   3045f:	83 c4 10             	add    $0x10,%esp
			for( int i = 1; i <= argc; ++i ) {
   30462:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
   30469:	eb 4d                	jmp    304b8 <progABC+0x11e>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   3046b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   3046e:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   30475:	85 c0                	test   %eax,%eax
   30477:	74 0c                	je     30485 <progABC+0xeb>
   30479:	8b 45 ec             	mov    -0x14(%ebp),%eax
   3047c:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   30483:	eb 05                	jmp    3048a <progABC+0xf0>
   30485:	b8 58 42 03 00       	mov    $0x34258,%eax
   3048a:	83 ec 04             	sub    $0x4,%esp
   3048d:	50                   	push   %eax
   3048e:	68 5f 42 03 00       	push   $0x3425f
   30493:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30499:	50                   	push   %eax
   3049a:	e8 32 26 00 00       	call   32ad1 <sprint>
   3049f:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   304a2:	83 ec 0c             	sub    $0xc,%esp
   304a5:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   304ab:	50                   	push   %eax
   304ac:	e8 a1 24 00 00       	call   32952 <cwrites>
   304b1:	83 c4 10             	add    $0x10,%esp
			for( int i = 1; i <= argc; ++i ) {
   304b4:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   304b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   304bb:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   304be:	7e ab                	jle    3046b <progABC+0xd1>
			}
			cwrites( "\n" );
   304c0:	83 ec 0c             	sub    $0xc,%esp
   304c3:	68 63 42 03 00       	push   $0x34263
   304c8:	e8 85 24 00 00       	call   32952 <cwrites>
   304cd:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   304d0:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   304d4:	83 ec 0c             	sub    $0xc,%esp
   304d7:	50                   	push   %eax
   304d8:	e8 bd 24 00 00       	call   3299a <swritech>
   304dd:	83 c4 10             	add    $0x10,%esp
   304e0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   304e3:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   304e7:	74 2e                	je     30517 <progABC+0x17d>
		sprint( buf, "== %c, write #1 returned %d\n", ch, n );
   304e9:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   304ed:	ff 75 dc             	push   -0x24(%ebp)
   304f0:	50                   	push   %eax
   304f1:	68 65 42 03 00       	push   $0x34265
   304f6:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   304fc:	50                   	push   %eax
   304fd:	e8 cf 25 00 00       	call   32ad1 <sprint>
   30502:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   30505:	83 ec 0c             	sub    $0xc,%esp
   30508:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3050e:	50                   	push   %eax
   3050f:	e8 3e 24 00 00       	call   32952 <cwrites>
   30514:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   30517:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   3051e:	eb 61                	jmp    30581 <progABC+0x1e7>
		DELAY(STD);
   30520:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   30527:	eb 04                	jmp    3052d <progABC+0x193>
   30529:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   3052d:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   30534:	7e f3                	jle    30529 <progABC+0x18f>
		n = swritech( ch );
   30536:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   3053a:	83 ec 0c             	sub    $0xc,%esp
   3053d:	50                   	push   %eax
   3053e:	e8 57 24 00 00       	call   3299a <swritech>
   30543:	83 c4 10             	add    $0x10,%esp
   30546:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   30549:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   3054d:	74 2e                	je     3057d <progABC+0x1e3>
			sprint( buf, "== %c, write #2 returned %d\n", ch, n );
   3054f:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   30553:	ff 75 dc             	push   -0x24(%ebp)
   30556:	50                   	push   %eax
   30557:	68 82 42 03 00       	push   $0x34282
   3055c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30562:	50                   	push   %eax
   30563:	e8 69 25 00 00       	call   32ad1 <sprint>
   30568:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   3056b:	83 ec 0c             	sub    $0xc,%esp
   3056e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30574:	50                   	push   %eax
   30575:	e8 d8 23 00 00       	call   32952 <cwrites>
   3057a:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   3057d:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   30581:	8b 45 e8             	mov    -0x18(%ebp),%eax
   30584:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   30587:	7c 97                	jl     30520 <progABC+0x186>
		}
	}

	// all done - exit status is 50, 51, or 52
	exit( 50 + (ch - 'A') );
   30589:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   3058d:	83 e8 0f             	sub    $0xf,%eax
   30590:	83 ec 0c             	sub    $0xc,%esp
   30593:	50                   	push   %eax
   30594:	e8 6a 24 00 00       	call   32a03 <exit>
   30599:	83 c4 10             	add    $0x10,%esp

	// should never reach this code; if we do, something is
	// wrong with exit(), so we'll report it

	char msg[] = "*1*";
   3059c:	c7 85 44 ff ff ff 2a 	movl   $0x2a312a,-0xbc(%ebp)
   305a3:	31 2a 00 
	msg[1] = ch;
   305a6:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   305aa:	88 85 45 ff ff ff    	mov    %al,-0xbb(%ebp)
	n = write( CHAN_SIO, msg, 3 );	  /* shouldn't happen! */
   305b0:	83 ec 04             	sub    $0x4,%esp
   305b3:	6a 03                	push   $0x3
   305b5:	8d 85 44 ff ff ff    	lea    -0xbc(%ebp),%eax
   305bb:	50                   	push   %eax
   305bc:	6a 01                	push   $0x1
   305be:	e8 68 24 00 00       	call   32a2b <write>
   305c3:	83 c4 10             	add    $0x10,%esp
   305c6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 3 ) {
   305c9:	83 7d dc 03          	cmpl   $0x3,-0x24(%ebp)
   305cd:	74 2e                	je     305fd <progABC+0x263>
		sprint( buf, "User %c, write #3 returned %d\n", ch, n );
   305cf:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   305d3:	ff 75 dc             	push   -0x24(%ebp)
   305d6:	50                   	push   %eax
   305d7:	68 a0 42 03 00       	push   $0x342a0
   305dc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   305e2:	50                   	push   %eax
   305e3:	e8 e9 24 00 00       	call   32ad1 <sprint>
   305e8:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   305eb:	83 ec 0c             	sub    $0xc,%esp
   305ee:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   305f4:	50                   	push   %eax
   305f5:	e8 58 23 00 00       	call   32952 <cwrites>
   305fa:	83 c4 10             	add    $0x10,%esp
	}

	// this should really get us out of here
	return( 99 );
   305fd:	b8 63 00 00 00       	mov    $0x63,%eax
}
   30602:	c9                   	leave  
   30603:	c3                   	ret    

00030604 <progDE>:
**	 where X varies depending on which "user program" this is (D, E)
**	       x is the ID character
**		   n is the iteration count
*/

USERMAIN( progDE ) {
   30604:	55                   	push   %ebp
   30605:	89 e5                	mov    %esp,%ebp
   30607:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	int n;
	int count = 30;	  // default iteration count
   3060d:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '2';	  // default character to print
   30614:	c6 45 f3 32          	movb   $0x32,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progDE" );
   30618:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   3061f:	00 00 00 
   30622:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   30629:	00 00 00 
   3062c:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   30633:	00 00 00 
   30636:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   3063d:	00 00 00 
   30640:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   30647:	00 00 00 
   3064a:	83 ec 0c             	sub    $0xc,%esp
   3064d:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   30653:	50                   	push   %eax
   30654:	6a 05                	push   $0x5
   30656:	6a 0d                	push   $0xd
   30658:	ff 75 08             	push   0x8(%ebp)
   3065b:	6a 03                	push   $0x3
   3065d:	e8 5d 20 00 00       	call   326bf <parseArgs>
   30662:	83 c4 20             	add    $0x20,%esp
   30665:	89 45 e0             	mov    %eax,-0x20(%ebp)
	switch( argc ) {
   30668:	83 7d e0 02          	cmpl   $0x2,-0x20(%ebp)
   3066c:	74 1d                	je     3068b <progDE+0x87>
   3066e:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
   30672:	75 28                	jne    3069c <progDE+0x98>
	case 3:	count = str2int( argv[2], 10 );
   30674:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   3067a:	83 ec 08             	sub    $0x8,%esp
   3067d:	6a 0a                	push   $0xa
   3067f:	50                   	push   %eax
   30680:	e8 c1 26 00 00       	call   32d46 <str2int>
   30685:	83 c4 10             	add    $0x10,%esp
   30688:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   3068b:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   30691:	0f b6 00             	movzbl (%eax),%eax
   30694:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   30697:	e9 9e 00 00 00       	jmp    3073a <progDE+0x136>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   3069c:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   306a2:	ff 75 e0             	push   -0x20(%ebp)
   306a5:	50                   	push   %eax
   306a6:	68 bf 42 03 00       	push   $0x342bf
   306ab:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   306b1:	50                   	push   %eax
   306b2:	e8 1a 24 00 00       	call   32ad1 <sprint>
   306b7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   306ba:	83 ec 0c             	sub    $0xc,%esp
   306bd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   306c3:	50                   	push   %eax
   306c4:	e8 89 22 00 00       	call   32952 <cwrites>
   306c9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   306cc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   306d3:	eb 4d                	jmp    30722 <progDE+0x11e>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   306d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   306d8:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   306df:	85 c0                	test   %eax,%eax
   306e1:	74 0c                	je     306ef <progDE+0xeb>
   306e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   306e6:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   306ed:	eb 05                	jmp    306f4 <progDE+0xf0>
   306ef:	b8 d3 42 03 00       	mov    $0x342d3,%eax
   306f4:	83 ec 04             	sub    $0x4,%esp
   306f7:	50                   	push   %eax
   306f8:	68 da 42 03 00       	push   $0x342da
   306fd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30703:	50                   	push   %eax
   30704:	e8 c8 23 00 00       	call   32ad1 <sprint>
   30709:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   3070c:	83 ec 0c             	sub    $0xc,%esp
   3070f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30715:	50                   	push   %eax
   30716:	e8 37 22 00 00       	call   32952 <cwrites>
   3071b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   3071e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   30722:	8b 45 ec             	mov    -0x14(%ebp),%eax
   30725:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   30728:	7e ab                	jle    306d5 <progDE+0xd1>
			}
			cwrites( "\n" );
   3072a:	83 ec 0c             	sub    $0xc,%esp
   3072d:	68 de 42 03 00       	push   $0x342de
   30732:	e8 1b 22 00 00       	call   32952 <cwrites>
   30737:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	n = swritech( ch );
   3073a:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   3073e:	83 ec 0c             	sub    $0xc,%esp
   30741:	50                   	push   %eax
   30742:	e8 53 22 00 00       	call   3299a <swritech>
   30747:	83 c4 10             	add    $0x10,%esp
   3074a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   3074d:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   30751:	74 2e                	je     30781 <progDE+0x17d>
		sprint( buf, "== %c, write #1 returned %d\n", ch, n );
   30753:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   30757:	ff 75 dc             	push   -0x24(%ebp)
   3075a:	50                   	push   %eax
   3075b:	68 e0 42 03 00       	push   $0x342e0
   30760:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30766:	50                   	push   %eax
   30767:	e8 65 23 00 00       	call   32ad1 <sprint>
   3076c:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   3076f:	83 ec 0c             	sub    $0xc,%esp
   30772:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   30778:	50                   	push   %eax
   30779:	e8 d4 21 00 00       	call   32952 <cwrites>
   3077e:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   30781:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   30788:	eb 61                	jmp    307eb <progDE+0x1e7>
		DELAY(STD);
   3078a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   30791:	eb 04                	jmp    30797 <progDE+0x193>
   30793:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   30797:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   3079e:	7e f3                	jle    30793 <progDE+0x18f>
		n = swritech( ch );
   307a0:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   307a4:	83 ec 0c             	sub    $0xc,%esp
   307a7:	50                   	push   %eax
   307a8:	e8 ed 21 00 00       	call   3299a <swritech>
   307ad:	83 c4 10             	add    $0x10,%esp
   307b0:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   307b3:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   307b7:	74 2e                	je     307e7 <progDE+0x1e3>
			sprint( buf, "== %c, write #2 returned %d\n", ch, n );
   307b9:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   307bd:	ff 75 dc             	push   -0x24(%ebp)
   307c0:	50                   	push   %eax
   307c1:	68 fd 42 03 00       	push   $0x342fd
   307c6:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   307cc:	50                   	push   %eax
   307cd:	e8 ff 22 00 00       	call   32ad1 <sprint>
   307d2:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   307d5:	83 ec 0c             	sub    $0xc,%esp
   307d8:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   307de:	50                   	push   %eax
   307df:	e8 6e 21 00 00       	call   32952 <cwrites>
   307e4:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   307e7:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   307eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
   307ee:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   307f1:	7c 97                	jl     3078a <progDE+0x186>
		}
	}

	// all done! return status 60 or 61
	return( 60 + (ch - 'D') );
   307f3:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   307f7:	83 e8 08             	sub    $0x8,%eax
}
   307fa:	c9                   	leave  
   307fb:	c3                   	ret    

000307fc <progFG>:
**	 where X varies depending on how it's invoked (F, G)
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progFG ) {
   307fc:	55                   	push   %ebp
   307fd:	89 e5                	mov    %esp,%ebp
   307ff:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char ch = '3';	// default character to print
   30805:	c6 45 df 33          	movb   $0x33,-0x21(%ebp)
	int nap = 10;	// default sleep time
   30809:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
	int count = 30;	// iteration count
   30810:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progFG" );
   30817:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   3081e:	00 00 00 
   30821:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   30828:	00 00 00 
   3082b:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   30832:	00 00 00 
   30835:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   3083c:	00 00 00 
   3083f:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   30846:	00 00 00 
   30849:	83 ec 0c             	sub    $0xc,%esp
   3084c:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   30852:	50                   	push   %eax
   30853:	6a 05                	push   $0x5
   30855:	6a 0d                	push   $0xd
   30857:	ff 75 08             	push   0x8(%ebp)
   3085a:	6a 03                	push   $0x3
   3085c:	e8 5e 1e 00 00       	call   326bf <parseArgs>
   30861:	83 c4 20             	add    $0x20,%esp
   30864:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch( argc ) {
   30867:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
   3086b:	74 1d                	je     3088a <progFG+0x8e>
   3086d:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
   30871:	75 28                	jne    3089b <progFG+0x9f>
	case 3:	count = str2int( argv[2], 10 );
   30873:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   30879:	83 ec 08             	sub    $0x8,%esp
   3087c:	6a 0a                	push   $0xa
   3087e:	50                   	push   %eax
   3087f:	e8 c2 24 00 00       	call   32d46 <str2int>
   30884:	83 c4 10             	add    $0x10,%esp
   30887:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   3088a:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   30890:	0f b6 00             	movzbl (%eax),%eax
   30893:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   30896:	e9 9e 00 00 00       	jmp    30939 <progFG+0x13d>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   3089b:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   308a1:	ff 75 e4             	push   -0x1c(%ebp)
   308a4:	50                   	push   %eax
   308a5:	68 1a 43 03 00       	push   $0x3431a
   308aa:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   308b0:	50                   	push   %eax
   308b1:	e8 1b 22 00 00       	call   32ad1 <sprint>
   308b6:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   308b9:	83 ec 0c             	sub    $0xc,%esp
   308bc:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   308c2:	50                   	push   %eax
   308c3:	e8 8a 20 00 00       	call   32952 <cwrites>
   308c8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   308cb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   308d2:	eb 4d                	jmp    30921 <progFG+0x125>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   308d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
   308d7:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   308de:	85 c0                	test   %eax,%eax
   308e0:	74 0c                	je     308ee <progFG+0xf2>
   308e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
   308e5:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   308ec:	eb 05                	jmp    308f3 <progFG+0xf7>
   308ee:	b8 2e 43 03 00       	mov    $0x3432e,%eax
   308f3:	83 ec 04             	sub    $0x4,%esp
   308f6:	50                   	push   %eax
   308f7:	68 35 43 03 00       	push   $0x34335
   308fc:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   30902:	50                   	push   %eax
   30903:	e8 c9 21 00 00       	call   32ad1 <sprint>
   30908:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   3090b:	83 ec 0c             	sub    $0xc,%esp
   3090e:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   30914:	50                   	push   %eax
   30915:	e8 38 20 00 00       	call   32952 <cwrites>
   3091a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   3091d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   30921:	8b 45 f0             	mov    -0x10(%ebp),%eax
   30924:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
   30927:	7e ab                	jle    308d4 <progFG+0xd8>
			}
			cwrites( "\n" );
   30929:	83 ec 0c             	sub    $0xc,%esp
   3092c:	68 39 43 03 00       	push   $0x34339
   30931:	e8 1c 20 00 00       	call   32952 <cwrites>
   30936:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   30939:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   3093d:	0f be c0             	movsbl %al,%eax
   30940:	83 ec 0c             	sub    $0xc,%esp
   30943:	50                   	push   %eax
   30944:	e8 51 20 00 00       	call   3299a <swritech>
   30949:	83 c4 10             	add    $0x10,%esp
   3094c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if( n != 1 ) {
   3094f:	83 7d e0 01          	cmpl   $0x1,-0x20(%ebp)
   30953:	74 31                	je     30986 <progFG+0x18a>
		sprint( buf, "=== %c, write #1 returned %d\n", ch, n );
   30955:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   30959:	0f be c0             	movsbl %al,%eax
   3095c:	ff 75 e0             	push   -0x20(%ebp)
   3095f:	50                   	push   %eax
   30960:	68 3b 43 03 00       	push   $0x3433b
   30965:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   3096b:	50                   	push   %eax
   3096c:	e8 60 21 00 00       	call   32ad1 <sprint>
   30971:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   30974:	83 ec 0c             	sub    $0xc,%esp
   30977:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   3097d:	50                   	push   %eax
   3097e:	e8 cf 1f 00 00       	call   32952 <cwrites>
   30983:	83 c4 10             	add    $0x10,%esp
	}

	write( CHAN_SIO, &ch, 1 );
   30986:	83 ec 04             	sub    $0x4,%esp
   30989:	6a 01                	push   $0x1
   3098b:	8d 45 df             	lea    -0x21(%ebp),%eax
   3098e:	50                   	push   %eax
   3098f:	6a 01                	push   $0x1
   30991:	e8 95 20 00 00       	call   32a2b <write>
   30996:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   30999:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   309a0:	eb 2c                	jmp    309ce <progFG+0x1d2>
		sleep( SEC_TO_MS(nap) );
   309a2:	8b 45 e8             	mov    -0x18(%ebp),%eax
   309a5:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   309ab:	83 ec 0c             	sub    $0xc,%esp
   309ae:	50                   	push   %eax
   309af:	e8 7f 20 00 00       	call   32a33 <sleep>
   309b4:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   309b7:	83 ec 04             	sub    $0x4,%esp
   309ba:	6a 01                	push   $0x1
   309bc:	8d 45 df             	lea    -0x21(%ebp),%eax
   309bf:	50                   	push   %eax
   309c0:	6a 01                	push   $0x1
   309c2:	e8 64 20 00 00       	call   32a2b <write>
   309c7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   309ca:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   309ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
   309d1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   309d4:	7c cc                	jl     309a2 <progFG+0x1a6>
	}

	exit( 0 );
   309d6:	83 ec 0c             	sub    $0xc,%esp
   309d9:	6a 00                	push   $0x0
   309db:	e8 23 20 00 00       	call   32a03 <exit>
   309e0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   309e3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   309e8:	c9                   	leave  
   309e9:	c3                   	ret    

000309ea <progH>:
** Invoked as:  progH  x  n
**	 where x is the ID character
**		   n is the number of children to spawn
*/

USERMAIN( progH ) {
   309ea:	55                   	push   %ebp
   309eb:	89 e5                	mov    %esp,%ebp
   309ed:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	int32_t ret = 0;  // return value
   309f3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int count = 5;	  // child count
   309fa:	c7 45 f0 05 00 00 00 	movl   $0x5,-0x10(%ebp)
	char ch = 'h';	  // default character to print
   30a01:	c6 45 ef 68          	movb   $0x68,-0x11(%ebp)
	char buf[128];
	pid_t whom;

	// process the argument(s)
	ARG_PROC( 3, args, 5, argc, "progH" );
   30a05:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
   30a0c:	00 00 00 
   30a0f:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
   30a16:	00 00 00 
   30a19:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   30a20:	00 00 00 
   30a23:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   30a2a:	00 00 00 
   30a2d:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   30a34:	00 00 00 
   30a37:	83 ec 0c             	sub    $0xc,%esp
   30a3a:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
   30a40:	50                   	push   %eax
   30a41:	6a 05                	push   $0x5
   30a43:	6a 0d                	push   $0xd
   30a45:	ff 75 08             	push   0x8(%ebp)
   30a48:	6a 03                	push   $0x3
   30a4a:	e8 70 1c 00 00       	call   326bf <parseArgs>
   30a4f:	83 c4 20             	add    $0x20,%esp
   30a52:	89 45 e0             	mov    %eax,-0x20(%ebp)
	const char *name = argv[0];
   30a55:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
   30a5b:	89 45 dc             	mov    %eax,-0x24(%ebp)

	switch( argc ) {
   30a5e:	83 7d e0 02          	cmpl   $0x2,-0x20(%ebp)
   30a62:	74 1d                	je     30a81 <progH+0x97>
   30a64:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
   30a68:	75 28                	jne    30a92 <progH+0xa8>
	case 3:	count = str2int( argv[2], 10 );
   30a6a:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   30a70:	83 ec 08             	sub    $0x8,%esp
   30a73:	6a 0a                	push   $0xa
   30a75:	50                   	push   %eax
   30a76:	e8 cb 22 00 00       	call   32d46 <str2int>
   30a7b:	83 c4 10             	add    $0x10,%esp
   30a7e:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   30a81:	8b 85 44 ff ff ff    	mov    -0xbc(%ebp),%eax
   30a87:	0f b6 00             	movzbl (%eax),%eax
   30a8a:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   30a8d:	e9 9a 00 00 00       	jmp    30b2c <progH+0x142>
	default:
			sprint( buf, "%s: argc %d, args: ", name, argc );
   30a92:	ff 75 e0             	push   -0x20(%ebp)
   30a95:	ff 75 dc             	push   -0x24(%ebp)
   30a98:	68 5c 43 03 00       	push   $0x3435c
   30a9d:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   30aa3:	50                   	push   %eax
   30aa4:	e8 28 20 00 00       	call   32ad1 <sprint>
   30aa9:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   30aac:	83 ec 0c             	sub    $0xc,%esp
   30aaf:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   30ab5:	50                   	push   %eax
   30ab6:	e8 97 1e 00 00       	call   32952 <cwrites>
   30abb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   30abe:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   30ac5:	eb 4d                	jmp    30b14 <progH+0x12a>
				sprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   30ac7:	8b 45 e0             	mov    -0x20(%ebp),%eax
   30aca:	8b 84 85 40 ff ff ff 	mov    -0xc0(%ebp,%eax,4),%eax
   30ad1:	85 c0                	test   %eax,%eax
   30ad3:	74 0c                	je     30ae1 <progH+0xf7>
   30ad5:	8b 45 e0             	mov    -0x20(%ebp),%eax
   30ad8:	8b 84 85 40 ff ff ff 	mov    -0xc0(%ebp,%eax,4),%eax
   30adf:	eb 05                	jmp    30ae6 <progH+0xfc>
   30ae1:	b8 70 43 03 00       	mov    $0x34370,%eax
   30ae6:	83 ec 04             	sub    $0x4,%esp
   30ae9:	50                   	push   %eax
   30aea:	68 77 43 03 00       	push   $0x34377
   30aef:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   30af5:	50                   	push   %eax
   30af6:	e8 d6 1f 00 00       	call   32ad1 <sprint>
   30afb:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   30afe:	83 ec 0c             	sub    $0xc,%esp
   30b01:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   30b07:	50                   	push   %eax
   30b08:	e8 45 1e 00 00       	call   32952 <cwrites>
   30b0d:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   30b10:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   30b14:	8b 45 e8             	mov    -0x18(%ebp),%eax
   30b17:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   30b1a:	7e ab                	jle    30ac7 <progH+0xdd>
			}
			cwrites( "\n" );
   30b1c:	83 ec 0c             	sub    $0xc,%esp
   30b1f:	68 7b 43 03 00       	push   $0x3437b
   30b24:	e8 29 1e 00 00       	call   32952 <cwrites>
   30b29:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	swritech( ch );
   30b2c:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   30b30:	83 ec 0c             	sub    $0xc,%esp
   30b33:	50                   	push   %eax
   30b34:	e8 61 1e 00 00       	call   3299a <swritech>
   30b39:	83 c4 10             	add    $0x10,%esp

	// we spawn user Z and then exit before it can terminate
	// progZ 'Z' 10

	char *argz = "progZ\rZ\r10";
   30b3c:	c7 45 d8 7d 43 03 00 	movl   $0x3437d,-0x28(%ebp)

	for( int i = 0; i < count; ++i ) {
   30b43:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   30b4a:	eb 53                	jmp    30b9f <progH+0x1b5>

		// spawn a child
		whom = spawn( (uint32_t) progZ, argz );
   30b4c:	b8 d3 24 03 00       	mov    $0x324d3,%eax
   30b51:	83 ec 08             	sub    $0x8,%esp
   30b54:	ff 75 d8             	push   -0x28(%ebp)
   30b57:	50                   	push   %eax
   30b58:	e8 0b 1d 00 00       	call   32868 <spawn>
   30b5d:	83 c4 10             	add    $0x10,%esp
   30b60:	89 45 d4             	mov    %eax,-0x2c(%ebp)

		// our exit status is the number of failed spawn() calls
		if( whom < 0 ) {
   30b63:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
   30b67:	79 32                	jns    30b9b <progH+0x1b1>
			sprint( buf, "!! %c spawn() failed, returned %d\n", ch, whom );
   30b69:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   30b6d:	ff 75 d4             	push   -0x2c(%ebp)
   30b70:	50                   	push   %eax
   30b71:	68 88 43 03 00       	push   $0x34388
   30b76:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   30b7c:	50                   	push   %eax
   30b7d:	e8 4f 1f 00 00       	call   32ad1 <sprint>
   30b82:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   30b85:	83 ec 0c             	sub    $0xc,%esp
   30b88:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   30b8e:	50                   	push   %eax
   30b8f:	e8 be 1d 00 00       	call   32952 <cwrites>
   30b94:	83 c4 10             	add    $0x10,%esp
			ret += 1;
   30b97:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
	for( int i = 0; i < count; ++i ) {
   30b9b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   30b9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   30ba2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   30ba5:	7c a5                	jl     30b4c <progH+0x162>
		}
	}

	// yield the CPU so that our child(ren) can run
	sleep( 0 );
   30ba7:	83 ec 0c             	sub    $0xc,%esp
   30baa:	6a 00                	push   $0x0
   30bac:	e8 82 1e 00 00       	call   32a33 <sleep>
   30bb1:	83 c4 10             	add    $0x10,%esp

	// announce our departure
	swritech( ch );
   30bb4:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   30bb8:	83 ec 0c             	sub    $0xc,%esp
   30bbb:	50                   	push   %eax
   30bbc:	e8 d9 1d 00 00       	call   3299a <swritech>
   30bc1:	83 c4 10             	add    $0x10,%esp

	exit( ret );
   30bc4:	83 ec 0c             	sub    $0xc,%esp
   30bc7:	ff 75 f4             	push   -0xc(%ebp)
   30bca:	e8 34 1e 00 00       	call   32a03 <exit>
   30bcf:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   30bd2:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   30bd7:	c9                   	leave  
   30bd8:	c3                   	ret    

00030bd9 <progI>:
** Invoked as:  progI [ x [ n ] ]
**	 where x is the ID character (defaults to 'i')
**		   n is the number of children to spawn (defaults to 5)
*/

USERMAIN( progI ) {
   30bd9:	55                   	push   %ebp
   30bda:	89 e5                	mov    %esp,%ebp
   30bdc:	81 ec 98 01 00 00    	sub    $0x198,%esp
	int count = 5;	  // default child count
   30be2:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = 'i';	  // default character to print
   30be9:	c6 45 cf 69          	movb   $0x69,-0x31(%ebp)
	int nap = 5;	  // nap time
   30bed:	c7 45 e0 05 00 00 00 	movl   $0x5,-0x20(%ebp)
	char buf[128];
	char ch2[] = "*?*";
   30bf4:	c7 85 4b ff ff ff 2a 	movl   $0x2a3f2a,-0xb5(%ebp)
   30bfb:	3f 2a 00 
	pid_t children[MAX_CHILDREN];
	int nkids = 0;
   30bfe:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progI" );
   30c05:	c7 85 6c fe ff ff 00 	movl   $0x0,-0x194(%ebp)
   30c0c:	00 00 00 
   30c0f:	c7 85 70 fe ff ff 00 	movl   $0x0,-0x190(%ebp)
   30c16:	00 00 00 
   30c19:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
   30c20:	00 00 00 
   30c23:	c7 85 78 fe ff ff 00 	movl   $0x0,-0x188(%ebp)
   30c2a:	00 00 00 
   30c2d:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
   30c34:	00 00 00 
   30c37:	83 ec 0c             	sub    $0xc,%esp
   30c3a:	8d 85 6c fe ff ff    	lea    -0x194(%ebp),%eax
   30c40:	50                   	push   %eax
   30c41:	6a 05                	push   $0x5
   30c43:	6a 0d                	push   $0xd
   30c45:	ff 75 08             	push   0x8(%ebp)
   30c48:	6a 03                	push   $0x3
   30c4a:	e8 70 1a 00 00       	call   326bf <parseArgs>
   30c4f:	83 c4 20             	add    $0x20,%esp
   30c52:	89 45 dc             	mov    %eax,-0x24(%ebp)
	switch( argc ) {
   30c55:	83 7d dc 03          	cmpl   $0x3,-0x24(%ebp)
   30c59:	74 18                	je     30c73 <progI+0x9a>
   30c5b:	83 7d dc 03          	cmpl   $0x3,-0x24(%ebp)
   30c5f:	7f 3a                	jg     30c9b <progI+0xc2>
   30c61:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   30c65:	0f 84 d0 00 00 00    	je     30d3b <progI+0x162>
   30c6b:	83 7d dc 02          	cmpl   $0x2,-0x24(%ebp)
   30c6f:	74 19                	je     30c8a <progI+0xb1>
   30c71:	eb 28                	jmp    30c9b <progI+0xc2>
	case 3:	count = str2int( argv[2], 10 );
   30c73:	8b 85 74 fe ff ff    	mov    -0x18c(%ebp),%eax
   30c79:	83 ec 08             	sub    $0x8,%esp
   30c7c:	6a 0a                	push   $0xa
   30c7e:	50                   	push   %eax
   30c7f:	e8 c2 20 00 00       	call   32d46 <str2int>
   30c84:	83 c4 10             	add    $0x10,%esp
   30c87:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   30c8a:	8b 85 70 fe ff ff    	mov    -0x190(%ebp),%eax
   30c90:	0f b6 00             	movzbl (%eax),%eax
   30c93:	88 45 cf             	mov    %al,-0x31(%ebp)
			break;
   30c96:	e9 a1 00 00 00       	jmp    30d3c <progI+0x163>
	case 1:	// just use the defaults
			break;
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   30c9b:	8b 85 6c fe ff ff    	mov    -0x194(%ebp),%eax
   30ca1:	ff 75 dc             	push   -0x24(%ebp)
   30ca4:	50                   	push   %eax
   30ca5:	68 ab 43 03 00       	push   $0x343ab
   30caa:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   30cb0:	50                   	push   %eax
   30cb1:	e8 1b 1e 00 00       	call   32ad1 <sprint>
   30cb6:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   30cb9:	83 ec 0c             	sub    $0xc,%esp
   30cbc:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   30cc2:	50                   	push   %eax
   30cc3:	e8 8a 1c 00 00       	call   32952 <cwrites>
   30cc8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   30ccb:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   30cd2:	eb 4d                	jmp    30d21 <progI+0x148>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   30cd4:	8b 45 ec             	mov    -0x14(%ebp),%eax
   30cd7:	8b 84 85 6c fe ff ff 	mov    -0x194(%ebp,%eax,4),%eax
   30cde:	85 c0                	test   %eax,%eax
   30ce0:	74 0c                	je     30cee <progI+0x115>
   30ce2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   30ce5:	8b 84 85 6c fe ff ff 	mov    -0x194(%ebp,%eax,4),%eax
   30cec:	eb 05                	jmp    30cf3 <progI+0x11a>
   30cee:	b8 bf 43 03 00       	mov    $0x343bf,%eax
   30cf3:	83 ec 04             	sub    $0x4,%esp
   30cf6:	50                   	push   %eax
   30cf7:	68 c6 43 03 00       	push   $0x343c6
   30cfc:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   30d02:	50                   	push   %eax
   30d03:	e8 c9 1d 00 00       	call   32ad1 <sprint>
   30d08:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   30d0b:	83 ec 0c             	sub    $0xc,%esp
   30d0e:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   30d14:	50                   	push   %eax
   30d15:	e8 38 1c 00 00       	call   32952 <cwrites>
   30d1a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   30d1d:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   30d21:	8b 45 ec             	mov    -0x14(%ebp),%eax
   30d24:	3b 45 dc             	cmp    -0x24(%ebp),%eax
   30d27:	7e ab                	jle    30cd4 <progI+0xfb>
			}
			cwrites( "\n" );
   30d29:	83 ec 0c             	sub    $0xc,%esp
   30d2c:	68 ca 43 03 00       	push   $0x343ca
   30d31:	e8 1c 1c 00 00       	call   32952 <cwrites>
   30d36:	83 c4 10             	add    $0x10,%esp
   30d39:	eb 01                	jmp    30d3c <progI+0x163>
			break;
   30d3b:	90                   	nop
	}

	// secondary output (for indicating errors)
	ch2[1] = ch;
   30d3c:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   30d40:	88 85 4c ff ff ff    	mov    %al,-0xb4(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   30d46:	83 ec 04             	sub    $0x4,%esp
   30d49:	6a 01                	push   $0x1
   30d4b:	8d 45 cf             	lea    -0x31(%ebp),%eax
   30d4e:	50                   	push   %eax
   30d4f:	6a 01                	push   $0x1
   30d51:	e8 d5 1c 00 00       	call   32a2b <write>
   30d56:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	// we run:	progW 10 5

	char *argw = "progW\rW\r10\r5";
   30d59:	c7 45 d8 cc 43 03 00 	movl   $0x343cc,-0x28(%ebp)

	for( int i = 0; i < count; ++i ) {
   30d60:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   30d67:	eb 5b                	jmp    30dc4 <progI+0x1eb>
		pid_t whom = spawn( (uint32_t) progW, argw );
   30d69:	b8 14 1f 03 00       	mov    $0x31f14,%eax
   30d6e:	83 ec 08             	sub    $0x8,%esp
   30d71:	ff 75 d8             	push   -0x28(%ebp)
   30d74:	50                   	push   %eax
   30d75:	e8 ee 1a 00 00       	call   32868 <spawn>
   30d7a:	83 c4 10             	add    $0x10,%esp
   30d7d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if( whom < 0 ) {
   30d80:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
   30d84:	79 14                	jns    30d9a <progI+0x1c1>
			swrites( ch2 );
   30d86:	83 ec 0c             	sub    $0xc,%esp
   30d89:	8d 85 4b ff ff ff    	lea    -0xb5(%ebp),%eax
   30d8f:	50                   	push   %eax
   30d90:	e8 26 1c 00 00       	call   329bb <swrites>
   30d95:	83 c4 10             	add    $0x10,%esp
   30d98:	eb 26                	jmp    30dc0 <progI+0x1e7>
		} else {
			swritech( ch );
   30d9a:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   30d9e:	0f be c0             	movsbl %al,%eax
   30da1:	83 ec 0c             	sub    $0xc,%esp
   30da4:	50                   	push   %eax
   30da5:	e8 f0 1b 00 00       	call   3299a <swritech>
   30daa:	83 c4 10             	add    $0x10,%esp
			children[nkids++] = whom;
   30dad:	8b 45 f0             	mov    -0x10(%ebp),%eax
   30db0:	8d 50 01             	lea    0x1(%eax),%edx
   30db3:	89 55 f0             	mov    %edx,-0x10(%ebp)
   30db6:	8b 55 d0             	mov    -0x30(%ebp),%edx
   30db9:	89 94 85 80 fe ff ff 	mov    %edx,-0x180(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   30dc0:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   30dc4:	8b 45 e8             	mov    -0x18(%ebp),%eax
   30dc7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   30dca:	7c 9d                	jl     30d69 <progI+0x190>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   30dcc:	8b 45 e0             	mov    -0x20(%ebp),%eax
   30dcf:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   30dd5:	83 ec 0c             	sub    $0xc,%esp
   30dd8:	50                   	push   %eax
   30dd9:	e8 55 1c 00 00       	call   32a33 <sleep>
   30dde:	83 c4 10             	add    $0x10,%esp

	// collect child information
	while( 1 ) {
		pid_t n = wait( NULL );
   30de1:	83 ec 0c             	sub    $0xc,%esp
   30de4:	6a 00                	push   $0x0
   30de6:	e8 20 1c 00 00       	call   32a0b <wait>
   30deb:	83 c4 10             	add    $0x10,%esp
   30dee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if( n == S_NO_CHILD ) {
   30df1:	83 7d d4 fc          	cmpl   $0xfffffffc,-0x2c(%ebp)
   30df5:	74 7d                	je     30e74 <progI+0x29b>
			// all done!
			break;
		}
		for( int i = 0; i < count; ++i ) {
   30df7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   30dfe:	eb 52                	jmp    30e52 <progI+0x279>
			if( children[i] == n ) {
   30e00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   30e03:	8b 84 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%eax
   30e0a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
   30e0d:	75 3f                	jne    30e4e <progI+0x275>
				sprint( buf, "== %c: child %d (%d)\n", ch, i, children[i] );
   30e0f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   30e12:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   30e19:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   30e1d:	0f be c0             	movsbl %al,%eax
   30e20:	83 ec 0c             	sub    $0xc,%esp
   30e23:	52                   	push   %edx
   30e24:	ff 75 e4             	push   -0x1c(%ebp)
   30e27:	50                   	push   %eax
   30e28:	68 d9 43 03 00       	push   $0x343d9
   30e2d:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   30e33:	50                   	push   %eax
   30e34:	e8 98 1c 00 00       	call   32ad1 <sprint>
   30e39:	83 c4 20             	add    $0x20,%esp
				cwrites( buf );
   30e3c:	83 ec 0c             	sub    $0xc,%esp
   30e3f:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   30e45:	50                   	push   %eax
   30e46:	e8 07 1b 00 00       	call   32952 <cwrites>
   30e4b:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < count; ++i ) {
   30e4e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   30e52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   30e55:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   30e58:	7c a6                	jl     30e00 <progI+0x227>
			}
		}
		sleep( SEC_TO_MS(nap) );
   30e5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
   30e5d:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   30e63:	83 ec 0c             	sub    $0xc,%esp
   30e66:	50                   	push   %eax
   30e67:	e8 c7 1b 00 00       	call   32a33 <sleep>
   30e6c:	83 c4 10             	add    $0x10,%esp
	while( 1 ) {
   30e6f:	e9 6d ff ff ff       	jmp    30de1 <progI+0x208>
			break;
   30e74:	90                   	nop
	};

	// let init() clean up after us!

	exit( 0 );
   30e75:	83 ec 0c             	sub    $0xc,%esp
   30e78:	6a 00                	push   $0x0
   30e7a:	e8 84 1b 00 00       	call   32a03 <exit>
   30e7f:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   30e82:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   30e87:	c9                   	leave  
   30e88:	c3                   	ret    

00030e89 <progJ>:
** Invoked as:  progJ  x  [ n ]
**	 where x is the ID character
**		   n is the number of children to spawn (defaults to 2 * N_PROCS)
*/

USERMAIN( progJ ) {
   30e89:	55                   	push   %ebp
   30e8a:	89 e5                	mov    %esp,%ebp
   30e8c:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	int count = 2 * N_PROCS;	// number of children to spawn
   30e92:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
	char ch = 'j';				// default character to print
   30e99:	c6 45 df 6a          	movb   $0x6a,-0x21(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progJ" );
   30e9d:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   30ea4:	00 00 00 
   30ea7:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   30eae:	00 00 00 
   30eb1:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   30eb8:	00 00 00 
   30ebb:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   30ec2:	00 00 00 
   30ec5:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   30ecc:	00 00 00 
   30ecf:	83 ec 0c             	sub    $0xc,%esp
   30ed2:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   30ed8:	50                   	push   %eax
   30ed9:	6a 05                	push   $0x5
   30edb:	6a 0d                	push   $0xd
   30edd:	ff 75 08             	push   0x8(%ebp)
   30ee0:	6a 03                	push   $0x3
   30ee2:	e8 d8 17 00 00       	call   326bf <parseArgs>
   30ee7:	83 c4 20             	add    $0x20,%esp
   30eea:	89 45 e8             	mov    %eax,-0x18(%ebp)
	switch( argc ) {
   30eed:	83 7d e8 02          	cmpl   $0x2,-0x18(%ebp)
   30ef1:	74 1d                	je     30f10 <progJ+0x87>
   30ef3:	83 7d e8 03          	cmpl   $0x3,-0x18(%ebp)
   30ef7:	75 28                	jne    30f21 <progJ+0x98>
	case 3:	count = str2int( argv[2], 10 );
   30ef9:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   30eff:	83 ec 08             	sub    $0x8,%esp
   30f02:	6a 0a                	push   $0xa
   30f04:	50                   	push   %eax
   30f05:	e8 3c 1e 00 00       	call   32d46 <str2int>
   30f0a:	83 c4 10             	add    $0x10,%esp
   30f0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   30f10:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   30f16:	0f b6 00             	movzbl (%eax),%eax
   30f19:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   30f1c:	e9 9e 00 00 00       	jmp    30fbf <progJ+0x136>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   30f21:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   30f27:	ff 75 e8             	push   -0x18(%ebp)
   30f2a:	50                   	push   %eax
   30f2b:	68 ef 43 03 00       	push   $0x343ef
   30f30:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   30f36:	50                   	push   %eax
   30f37:	e8 95 1b 00 00       	call   32ad1 <sprint>
   30f3c:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   30f3f:	83 ec 0c             	sub    $0xc,%esp
   30f42:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   30f48:	50                   	push   %eax
   30f49:	e8 04 1a 00 00       	call   32952 <cwrites>
   30f4e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   30f51:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   30f58:	eb 4d                	jmp    30fa7 <progJ+0x11e>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   30f5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   30f5d:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   30f64:	85 c0                	test   %eax,%eax
   30f66:	74 0c                	je     30f74 <progJ+0xeb>
   30f68:	8b 45 f0             	mov    -0x10(%ebp),%eax
   30f6b:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   30f72:	eb 05                	jmp    30f79 <progJ+0xf0>
   30f74:	b8 03 44 03 00       	mov    $0x34403,%eax
   30f79:	83 ec 04             	sub    $0x4,%esp
   30f7c:	50                   	push   %eax
   30f7d:	68 0a 44 03 00       	push   $0x3440a
   30f82:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   30f88:	50                   	push   %eax
   30f89:	e8 43 1b 00 00       	call   32ad1 <sprint>
   30f8e:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   30f91:	83 ec 0c             	sub    $0xc,%esp
   30f94:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   30f9a:	50                   	push   %eax
   30f9b:	e8 b2 19 00 00       	call   32952 <cwrites>
   30fa0:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   30fa3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   30fa7:	8b 45 f0             	mov    -0x10(%ebp),%eax
   30faa:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   30fad:	7e ab                	jle    30f5a <progJ+0xd1>
			}
			cwrites( "\n" );
   30faf:	83 ec 0c             	sub    $0xc,%esp
   30fb2:	68 0e 44 03 00       	push   $0x3440e
   30fb7:	e8 96 19 00 00       	call   32952 <cwrites>
   30fbc:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   30fbf:	83 ec 04             	sub    $0x4,%esp
   30fc2:	6a 01                	push   $0x1
   30fc4:	8d 45 df             	lea    -0x21(%ebp),%eax
   30fc7:	50                   	push   %eax
   30fc8:	6a 01                	push   $0x1
   30fca:	e8 5c 1a 00 00       	call   32a2b <write>
   30fcf:	83 c4 10             	add    $0x10,%esp

	// set up the command-line arguments
	char *argy = "progY\rY\r10";
   30fd2:	c7 45 e4 10 44 03 00 	movl   $0x34410,-0x1c(%ebp)

	for( int i = 0; i < count ; ++i ) {
   30fd9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   30fe0:	eb 4a                	jmp    3102c <progJ+0x1a3>
		pid_t whom = spawn( (uint32_t) progY, argy );
   30fe2:	b8 0a 23 03 00       	mov    $0x3230a,%eax
   30fe7:	83 ec 08             	sub    $0x8,%esp
   30fea:	ff 75 e4             	push   -0x1c(%ebp)
   30fed:	50                   	push   %eax
   30fee:	e8 75 18 00 00       	call   32868 <spawn>
   30ff3:	83 c4 10             	add    $0x10,%esp
   30ff6:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 0 ) {
   30ff9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   30ffd:	79 16                	jns    31015 <progJ+0x18c>
			write( CHAN_SIO, "!j!", 3 );
   30fff:	83 ec 04             	sub    $0x4,%esp
   31002:	6a 03                	push   $0x3
   31004:	68 1b 44 03 00       	push   $0x3441b
   31009:	6a 01                	push   $0x1
   3100b:	e8 1b 1a 00 00       	call   32a2b <write>
   31010:	83 c4 10             	add    $0x10,%esp
   31013:	eb 13                	jmp    31028 <progJ+0x19f>
		} else {
			write( CHAN_SIO, &ch, 1 );
   31015:	83 ec 04             	sub    $0x4,%esp
   31018:	6a 01                	push   $0x1
   3101a:	8d 45 df             	lea    -0x21(%ebp),%eax
   3101d:	50                   	push   %eax
   3101e:	6a 01                	push   $0x1
   31020:	e8 06 1a 00 00       	call   32a2b <write>
   31025:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   31028:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   3102c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   3102f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   31032:	7c ae                	jl     30fe2 <progJ+0x159>
		}
	}

	exit( 0 );
   31034:	83 ec 0c             	sub    $0xc,%esp
   31037:	6a 00                	push   $0x0
   31039:	e8 c5 19 00 00       	call   32a03 <exit>
   3103e:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   31041:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   31046:	c9                   	leave  
   31047:	c3                   	ret    

00031048 <progKL>:
**	 where X varies (K, L)
**	       x is the ID character
**		   n is the iteration count (defaults to 5)
*/

USERMAIN( progKL ) {
   31048:	55                   	push   %ebp
   31049:	89 e5                	mov    %esp,%ebp
   3104b:	83 ec 68             	sub    $0x68,%esp
	int count = 5;			// default iteration count
   3104e:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '4';			// default character to print
   31055:	c6 45 df 34          	movb   $0x34,-0x21(%ebp)
	int nap = 30;			// nap time
   31059:	c7 45 e8 1e 00 00 00 	movl   $0x1e,-0x18(%ebp)
	char msg2[] = "*4*";	// "error" message to print
   31060:	c7 45 db 2a 34 2a 00 	movl   $0x2a342a,-0x25(%ebp)
	char buf[32];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progKL" );
   31067:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
   3106e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
   31075:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
   3107c:	c7 45 b0 00 00 00 00 	movl   $0x0,-0x50(%ebp)
   31083:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
   3108a:	83 ec 0c             	sub    $0xc,%esp
   3108d:	8d 45 a4             	lea    -0x5c(%ebp),%eax
   31090:	50                   	push   %eax
   31091:	6a 05                	push   $0x5
   31093:	6a 0d                	push   $0xd
   31095:	ff 75 08             	push   0x8(%ebp)
   31098:	6a 03                	push   $0x3
   3109a:	e8 20 16 00 00       	call   326bf <parseArgs>
   3109f:	83 c4 20             	add    $0x20,%esp
   310a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch( argc ) {
   310a5:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
   310a9:	74 1a                	je     310c5 <progKL+0x7d>
   310ab:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
   310af:	75 22                	jne    310d3 <progKL+0x8b>
	case 3:	count = str2int( argv[2], 10 );
   310b1:	8b 45 ac             	mov    -0x54(%ebp),%eax
   310b4:	83 ec 08             	sub    $0x8,%esp
   310b7:	6a 0a                	push   $0xa
   310b9:	50                   	push   %eax
   310ba:	e8 87 1c 00 00       	call   32d46 <str2int>
   310bf:	83 c4 10             	add    $0x10,%esp
   310c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   310c5:	8b 45 a8             	mov    -0x58(%ebp),%eax
   310c8:	0f b6 00             	movzbl (%eax),%eax
   310cb:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   310ce:	e9 8a 00 00 00       	jmp    3115d <progKL+0x115>
	default:
			sprint( buf, "%s: argc %d, args: ", "progKL", argc );
   310d3:	ff 75 e4             	push   -0x1c(%ebp)
   310d6:	68 1f 44 03 00       	push   $0x3441f
   310db:	68 26 44 03 00       	push   $0x34426
   310e0:	8d 45 bb             	lea    -0x45(%ebp),%eax
   310e3:	50                   	push   %eax
   310e4:	e8 e8 19 00 00       	call   32ad1 <sprint>
   310e9:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   310ec:	83 ec 0c             	sub    $0xc,%esp
   310ef:	8d 45 bb             	lea    -0x45(%ebp),%eax
   310f2:	50                   	push   %eax
   310f3:	e8 5a 18 00 00       	call   32952 <cwrites>
   310f8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   310fb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   31102:	eb 41                	jmp    31145 <progKL+0xfd>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   31104:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31107:	8b 44 85 a4          	mov    -0x5c(%ebp,%eax,4),%eax
   3110b:	85 c0                	test   %eax,%eax
   3110d:	74 09                	je     31118 <progKL+0xd0>
   3110f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31112:	8b 44 85 a4          	mov    -0x5c(%ebp,%eax,4),%eax
   31116:	eb 05                	jmp    3111d <progKL+0xd5>
   31118:	b8 3a 44 03 00       	mov    $0x3443a,%eax
   3111d:	83 ec 04             	sub    $0x4,%esp
   31120:	50                   	push   %eax
   31121:	68 41 44 03 00       	push   $0x34441
   31126:	8d 45 bb             	lea    -0x45(%ebp),%eax
   31129:	50                   	push   %eax
   3112a:	e8 a2 19 00 00       	call   32ad1 <sprint>
   3112f:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   31132:	83 ec 0c             	sub    $0xc,%esp
   31135:	8d 45 bb             	lea    -0x45(%ebp),%eax
   31138:	50                   	push   %eax
   31139:	e8 14 18 00 00       	call   32952 <cwrites>
   3113e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   31141:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   31145:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31148:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
   3114b:	7e b7                	jle    31104 <progKL+0xbc>
			}
			cwrites( "\n" );
   3114d:	83 ec 0c             	sub    $0xc,%esp
   31150:	68 45 44 03 00       	push   $0x34445
   31155:	e8 f8 17 00 00       	call   32952 <cwrites>
   3115a:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   3115d:	83 ec 04             	sub    $0x4,%esp
   31160:	6a 01                	push   $0x1
   31162:	8d 45 df             	lea    -0x21(%ebp),%eax
   31165:	50                   	push   %eax
   31166:	6a 01                	push   $0x1
   31168:	e8 be 18 00 00       	call   32a2b <write>
   3116d:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   31170:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   31177:	e9 89 00 00 00       	jmp    31205 <progKL+0x1bd>

		write( CHAN_SIO, &ch, 1 );
   3117c:	83 ec 04             	sub    $0x4,%esp
   3117f:	6a 01                	push   $0x1
   31181:	8d 45 df             	lea    -0x21(%ebp),%eax
   31184:	50                   	push   %eax
   31185:	6a 01                	push   $0x1
   31187:	e8 9f 18 00 00       	call   32a2b <write>
   3118c:	83 c4 10             	add    $0x10,%esp

		// second argument to X is 100 plus the iteration number
		sprint( buf, "progX\rX\r%d", 100 + i );
   3118f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31192:	83 c0 64             	add    $0x64,%eax
   31195:	83 ec 04             	sub    $0x4,%esp
   31198:	50                   	push   %eax
   31199:	68 47 44 03 00       	push   $0x34447
   3119e:	8d 45 bb             	lea    -0x45(%ebp),%eax
   311a1:	50                   	push   %eax
   311a2:	e8 2a 19 00 00       	call   32ad1 <sprint>
   311a7:	83 c4 10             	add    $0x10,%esp
		pid_t whom = spawn( (uint32_t) progX, buf );
   311aa:	ba 4d 21 03 00       	mov    $0x3214d,%edx
   311af:	83 ec 08             	sub    $0x8,%esp
   311b2:	8d 45 bb             	lea    -0x45(%ebp),%eax
   311b5:	50                   	push   %eax
   311b6:	52                   	push   %edx
   311b7:	e8 ac 16 00 00       	call   32868 <spawn>
   311bc:	83 c4 10             	add    $0x10,%esp
   311bf:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 0 ) {
   311c2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   311c6:	79 11                	jns    311d9 <progKL+0x191>
			swrites( msg2 );
   311c8:	83 ec 0c             	sub    $0xc,%esp
   311cb:	8d 45 db             	lea    -0x25(%ebp),%eax
   311ce:	50                   	push   %eax
   311cf:	e8 e7 17 00 00       	call   329bb <swrites>
   311d4:	83 c4 10             	add    $0x10,%esp
   311d7:	eb 13                	jmp    311ec <progKL+0x1a4>
		} else {
			write( CHAN_SIO, &ch, 1 );
   311d9:	83 ec 04             	sub    $0x4,%esp
   311dc:	6a 01                	push   $0x1
   311de:	8d 45 df             	lea    -0x21(%ebp),%eax
   311e1:	50                   	push   %eax
   311e2:	6a 01                	push   $0x1
   311e4:	e8 42 18 00 00       	call   32a2b <write>
   311e9:	83 c4 10             	add    $0x10,%esp
		}

		sleep( SEC_TO_MS(nap) );
   311ec:	8b 45 e8             	mov    -0x18(%ebp),%eax
   311ef:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   311f5:	83 ec 0c             	sub    $0xc,%esp
   311f8:	50                   	push   %eax
   311f9:	e8 35 18 00 00       	call   32a33 <sleep>
   311fe:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   31201:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   31205:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31208:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   3120b:	0f 8c 6b ff ff ff    	jl     3117c <progKL+0x134>
	}

	exit( 0 );
   31211:	83 ec 0c             	sub    $0xc,%esp
   31214:	6a 00                	push   $0x0
   31216:	e8 e8 17 00 00       	call   32a03 <exit>
   3121b:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   3121e:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   31223:	c9                   	leave  
   31224:	c3                   	ret    

00031225 <progMN>:
**	       x is the ID character
**		   n is the iteration count
**		   b is the w&z boolean
*/

USERMAIN( progMN ) {
   31225:	55                   	push   %ebp
   31226:	89 e5                	mov    %esp,%ebp
   31228:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	int count = 5;	// default iteration count
   3122e:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '5';	// default character to print
   31235:	c6 45 d7 35          	movb   $0x35,-0x29(%ebp)
	int alsoZ = 0;	// also do progZ?
   31239:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	char msgw[] = "*5w*";
   31240:	c7 45 d2 2a 35 77 2a 	movl   $0x2a77352a,-0x2e(%ebp)
   31247:	c6 45 d6 00          	movb   $0x0,-0x2a(%ebp)
	char msgz[] = "*5z*";
   3124b:	c7 45 cd 2a 35 7a 2a 	movl   $0x2a7a352a,-0x33(%ebp)
   31252:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progMN" );
   31256:	c7 85 38 ff ff ff 00 	movl   $0x0,-0xc8(%ebp)
   3125d:	00 00 00 
   31260:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
   31267:	00 00 00 
   3126a:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
   31271:	00 00 00 
   31274:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
   3127b:	00 00 00 
   3127e:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   31285:	00 00 00 
   31288:	83 ec 0c             	sub    $0xc,%esp
   3128b:	8d 85 38 ff ff ff    	lea    -0xc8(%ebp),%eax
   31291:	50                   	push   %eax
   31292:	6a 05                	push   $0x5
   31294:	6a 0d                	push   $0xd
   31296:	ff 75 08             	push   0x8(%ebp)
   31299:	6a 04                	push   $0x4
   3129b:	e8 1f 14 00 00       	call   326bf <parseArgs>
   312a0:	83 c4 20             	add    $0x20,%esp
   312a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch( argc ) {
   312a6:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   312aa:	74 14                	je     312c0 <progMN+0x9b>
   312ac:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   312b0:	7f 4a                	jg     312fc <progMN+0xd7>
   312b2:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
   312b6:	74 33                	je     312eb <progMN+0xc6>
   312b8:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
   312bc:	74 16                	je     312d4 <progMN+0xaf>
   312be:	eb 3c                	jmp    312fc <progMN+0xd7>
	case 4:	alsoZ = argv[3][0] == 't';
   312c0:	8b 85 44 ff ff ff    	mov    -0xbc(%ebp),%eax
   312c6:	0f b6 00             	movzbl (%eax),%eax
   312c9:	3c 74                	cmp    $0x74,%al
   312cb:	0f 94 c0             	sete   %al
   312ce:	0f b6 c0             	movzbl %al,%eax
   312d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = str2int( argv[2], 10 );
   312d4:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
   312da:	83 ec 08             	sub    $0x8,%esp
   312dd:	6a 0a                	push   $0xa
   312df:	50                   	push   %eax
   312e0:	e8 61 1a 00 00       	call   32d46 <str2int>
   312e5:	83 c4 10             	add    $0x10,%esp
   312e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   312eb:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
   312f1:	0f b6 00             	movzbl (%eax),%eax
   312f4:	88 45 d7             	mov    %al,-0x29(%ebp)
			break;
   312f7:	e9 9e 00 00 00       	jmp    3139a <progMN+0x175>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   312fc:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
   31302:	ff 75 e4             	push   -0x1c(%ebp)
   31305:	50                   	push   %eax
   31306:	68 52 44 03 00       	push   $0x34452
   3130b:	8d 85 4d ff ff ff    	lea    -0xb3(%ebp),%eax
   31311:	50                   	push   %eax
   31312:	e8 ba 17 00 00       	call   32ad1 <sprint>
   31317:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   3131a:	83 ec 0c             	sub    $0xc,%esp
   3131d:	8d 85 4d ff ff ff    	lea    -0xb3(%ebp),%eax
   31323:	50                   	push   %eax
   31324:	e8 29 16 00 00       	call   32952 <cwrites>
   31329:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   3132c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   31333:	eb 4d                	jmp    31382 <progMN+0x15d>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   31335:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31338:	8b 84 85 38 ff ff ff 	mov    -0xc8(%ebp,%eax,4),%eax
   3133f:	85 c0                	test   %eax,%eax
   31341:	74 0c                	je     3134f <progMN+0x12a>
   31343:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31346:	8b 84 85 38 ff ff ff 	mov    -0xc8(%ebp,%eax,4),%eax
   3134d:	eb 05                	jmp    31354 <progMN+0x12f>
   3134f:	b8 66 44 03 00       	mov    $0x34466,%eax
   31354:	83 ec 04             	sub    $0x4,%esp
   31357:	50                   	push   %eax
   31358:	68 6d 44 03 00       	push   $0x3446d
   3135d:	8d 85 4d ff ff ff    	lea    -0xb3(%ebp),%eax
   31363:	50                   	push   %eax
   31364:	e8 68 17 00 00       	call   32ad1 <sprint>
   31369:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   3136c:	83 ec 0c             	sub    $0xc,%esp
   3136f:	8d 85 4d ff ff ff    	lea    -0xb3(%ebp),%eax
   31375:	50                   	push   %eax
   31376:	e8 d7 15 00 00       	call   32952 <cwrites>
   3137b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   3137e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   31382:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31385:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
   31388:	7e ab                	jle    31335 <progMN+0x110>
			}
			cwrites( "\n" );
   3138a:	83 ec 0c             	sub    $0xc,%esp
   3138d:	68 71 44 03 00       	push   $0x34471
   31392:	e8 bb 15 00 00       	call   32952 <cwrites>
   31397:	83 c4 10             	add    $0x10,%esp
	}

	// update the extra message strings
	msgw[1] = msgz[1] = ch;
   3139a:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
   3139e:	88 45 ce             	mov    %al,-0x32(%ebp)
   313a1:	0f b6 45 ce          	movzbl -0x32(%ebp),%eax
   313a5:	88 45 d3             	mov    %al,-0x2d(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   313a8:	83 ec 04             	sub    $0x4,%esp
   313ab:	6a 01                	push   $0x1
   313ad:	8d 45 d7             	lea    -0x29(%ebp),%eax
   313b0:	50                   	push   %eax
   313b1:	6a 01                	push   $0x1
   313b3:	e8 73 16 00 00       	call   32a2b <write>
   313b8:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector(s)

	// W:  15 iterations, 5-second sleep
	char *argw = "progW\rW\r15\r5";
   313bb:	c7 45 e0 73 44 03 00 	movl   $0x34473,-0x20(%ebp)

	// Z:  15 iterations
	char *argz = "progZ\rZ\r15";
   313c2:	c7 45 dc 80 44 03 00 	movl   $0x34480,-0x24(%ebp)

	for( int i = 0; i < count; ++i ) {
   313c9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   313d0:	eb 75                	jmp    31447 <progMN+0x222>
		write( CHAN_SIO, &ch, 1 );
   313d2:	83 ec 04             	sub    $0x4,%esp
   313d5:	6a 01                	push   $0x1
   313d7:	8d 45 d7             	lea    -0x29(%ebp),%eax
   313da:	50                   	push   %eax
   313db:	6a 01                	push   $0x1
   313dd:	e8 49 16 00 00       	call   32a2b <write>
   313e2:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progW, argw	);
   313e5:	b8 14 1f 03 00       	mov    $0x31f14,%eax
   313ea:	83 ec 08             	sub    $0x8,%esp
   313ed:	ff 75 e0             	push   -0x20(%ebp)
   313f0:	50                   	push   %eax
   313f1:	e8 72 14 00 00       	call   32868 <spawn>
   313f6:	83 c4 10             	add    $0x10,%esp
   313f9:	89 45 d8             	mov    %eax,-0x28(%ebp)
		if( whom < 1 ) {
   313fc:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   31400:	7f 0f                	jg     31411 <progMN+0x1ec>
			swrites( msgw );
   31402:	83 ec 0c             	sub    $0xc,%esp
   31405:	8d 45 d2             	lea    -0x2e(%ebp),%eax
   31408:	50                   	push   %eax
   31409:	e8 ad 15 00 00       	call   329bb <swrites>
   3140e:	83 c4 10             	add    $0x10,%esp
		}
		if( alsoZ ) {
   31411:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   31415:	74 2c                	je     31443 <progMN+0x21e>
			whom = spawn( (uint32_t) progZ, argz );
   31417:	b8 d3 24 03 00       	mov    $0x324d3,%eax
   3141c:	83 ec 08             	sub    $0x8,%esp
   3141f:	ff 75 dc             	push   -0x24(%ebp)
   31422:	50                   	push   %eax
   31423:	e8 40 14 00 00       	call   32868 <spawn>
   31428:	83 c4 10             	add    $0x10,%esp
   3142b:	89 45 d8             	mov    %eax,-0x28(%ebp)
			if( whom < 1 ) {
   3142e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   31432:	7f 0f                	jg     31443 <progMN+0x21e>
				swrites( msgz );
   31434:	83 ec 0c             	sub    $0xc,%esp
   31437:	8d 45 cd             	lea    -0x33(%ebp),%eax
   3143a:	50                   	push   %eax
   3143b:	e8 7b 15 00 00       	call   329bb <swrites>
   31440:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   31443:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   31447:	8b 45 e8             	mov    -0x18(%ebp),%eax
   3144a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   3144d:	7c 83                	jl     313d2 <progMN+0x1ad>
			}
		}
	}

	exit( 0 );
   3144f:	83 ec 0c             	sub    $0xc,%esp
   31452:	6a 00                	push   $0x0
   31454:	e8 aa 15 00 00       	call   32a03 <exit>
   31459:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   3145c:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   31461:	c9                   	leave  
   31462:	c3                   	ret    

00031463 <progP>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 3)
**		   t is the sleep time (defaults to 2 seconds)
*/

USERMAIN( progP ) {
   31463:	55                   	push   %ebp
   31464:	89 e5                	mov    %esp,%ebp
   31466:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	int count = 3;	  // default iteration count
   3146c:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = 'p';	  // default character to print
   31473:	c6 45 df 70          	movb   $0x70,-0x21(%ebp)
	int nap = 2;	  // nap time
   31477:	c7 45 f0 02 00 00 00 	movl   $0x2,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progP" );
   3147e:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   31485:	00 00 00 
   31488:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   3148f:	00 00 00 
   31492:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   31499:	00 00 00 
   3149c:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   314a3:	00 00 00 
   314a6:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   314ad:	00 00 00 
   314b0:	83 ec 0c             	sub    $0xc,%esp
   314b3:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   314b9:	50                   	push   %eax
   314ba:	6a 05                	push   $0x5
   314bc:	6a 0d                	push   $0xd
   314be:	ff 75 08             	push   0x8(%ebp)
   314c1:	6a 04                	push   $0x4
   314c3:	e8 f7 11 00 00       	call   326bf <parseArgs>
   314c8:	83 c4 20             	add    $0x20,%esp
   314cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch( argc ) {
   314ce:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   314d2:	74 14                	je     314e8 <progP+0x85>
   314d4:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   314d8:	7f 4d                	jg     31527 <progP+0xc4>
   314da:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
   314de:	74 36                	je     31516 <progP+0xb3>
   314e0:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
   314e4:	74 19                	je     314ff <progP+0x9c>
   314e6:	eb 3f                	jmp    31527 <progP+0xc4>
	case 4:	nap = str2int( argv[3], 10 );
   314e8:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
   314ee:	83 ec 08             	sub    $0x8,%esp
   314f1:	6a 0a                	push   $0xa
   314f3:	50                   	push   %eax
   314f4:	e8 4d 18 00 00       	call   32d46 <str2int>
   314f9:	83 c4 10             	add    $0x10,%esp
   314fc:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = str2int( argv[2], 10 );
   314ff:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   31505:	83 ec 08             	sub    $0x8,%esp
   31508:	6a 0a                	push   $0xa
   3150a:	50                   	push   %eax
   3150b:	e8 36 18 00 00       	call   32d46 <str2int>
   31510:	83 c4 10             	add    $0x10,%esp
   31513:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   31516:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   3151c:	0f b6 00             	movzbl (%eax),%eax
   3151f:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   31522:	e9 9e 00 00 00       	jmp    315c5 <progP+0x162>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   31527:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   3152d:	ff 75 e4             	push   -0x1c(%ebp)
   31530:	50                   	push   %eax
   31531:	68 8b 44 03 00       	push   $0x3448b
   31536:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   3153c:	50                   	push   %eax
   3153d:	e8 8f 15 00 00       	call   32ad1 <sprint>
   31542:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   31545:	83 ec 0c             	sub    $0xc,%esp
   31548:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   3154e:	50                   	push   %eax
   3154f:	e8 fe 13 00 00       	call   32952 <cwrites>
   31554:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   31557:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   3155e:	eb 4d                	jmp    315ad <progP+0x14a>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   31560:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31563:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   3156a:	85 c0                	test   %eax,%eax
   3156c:	74 0c                	je     3157a <progP+0x117>
   3156e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31571:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   31578:	eb 05                	jmp    3157f <progP+0x11c>
   3157a:	b8 9f 44 03 00       	mov    $0x3449f,%eax
   3157f:	83 ec 04             	sub    $0x4,%esp
   31582:	50                   	push   %eax
   31583:	68 a6 44 03 00       	push   $0x344a6
   31588:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   3158e:	50                   	push   %eax
   3158f:	e8 3d 15 00 00       	call   32ad1 <sprint>
   31594:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   31597:	83 ec 0c             	sub    $0xc,%esp
   3159a:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   315a0:	50                   	push   %eax
   315a1:	e8 ac 13 00 00       	call   32952 <cwrites>
   315a6:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   315a9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   315ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
   315b0:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
   315b3:	7e ab                	jle    31560 <progP+0xfd>
			}
			cwrites( "\n" );
   315b5:	83 ec 0c             	sub    $0xc,%esp
   315b8:	68 aa 44 03 00       	push   $0x344aa
   315bd:	e8 90 13 00 00       	call   32952 <cwrites>
   315c2:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	time_t now = gettime();
   315c5:	e8 79 14 00 00       	call   32a43 <gettime>
   315ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
	sprint( buf, " P@%u", now );
   315cd:	83 ec 04             	sub    $0x4,%esp
   315d0:	ff 75 e0             	push   -0x20(%ebp)
   315d3:	68 ac 44 03 00       	push   $0x344ac
   315d8:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   315de:	50                   	push   %eax
   315df:	e8 ed 14 00 00       	call   32ad1 <sprint>
   315e4:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   315e7:	83 ec 0c             	sub    $0xc,%esp
   315ea:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   315f0:	50                   	push   %eax
   315f1:	e8 c5 13 00 00       	call   329bb <swrites>
   315f6:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count; ++i ) {
   315f9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   31600:	eb 2c                	jmp    3162e <progP+0x1cb>
		sleep( SEC_TO_MS(nap) );
   31602:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31605:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   3160b:	83 ec 0c             	sub    $0xc,%esp
   3160e:	50                   	push   %eax
   3160f:	e8 1f 14 00 00       	call   32a33 <sleep>
   31614:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   31617:	83 ec 04             	sub    $0x4,%esp
   3161a:	6a 01                	push   $0x1
   3161c:	8d 45 df             	lea    -0x21(%ebp),%eax
   3161f:	50                   	push   %eax
   31620:	6a 01                	push   $0x1
   31622:	e8 04 14 00 00       	call   32a2b <write>
   31627:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   3162a:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   3162e:	8b 45 e8             	mov    -0x18(%ebp),%eax
   31631:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   31634:	7c cc                	jl     31602 <progP+0x19f>
	}

	exit( 0 );
   31636:	83 ec 0c             	sub    $0xc,%esp
   31639:	6a 00                	push   $0x0
   3163b:	e8 c3 13 00 00       	call   32a03 <exit>
   31640:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   31643:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   31648:	c9                   	leave  
   31649:	c3                   	ret    

0003164a <progQ>:
**
** Invoked as:  progQ  x
**	 where x is the ID character
*/

USERMAIN( progQ ) {
   3164a:	55                   	push   %ebp
   3164b:	89 e5                	mov    %esp,%ebp
   3164d:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char ch = 'q';	  // default character to print
   31653:	c6 45 ef 71          	movb   $0x71,-0x11(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 2, args, 5, argc, "progQ" );
   31657:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   3165e:	00 00 00 
   31661:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
   31668:	00 00 00 
   3166b:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
   31672:	00 00 00 
   31675:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
   3167c:	00 00 00 
   3167f:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
   31686:	00 00 00 
   31689:	83 ec 0c             	sub    $0xc,%esp
   3168c:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   31692:	50                   	push   %eax
   31693:	6a 05                	push   $0x5
   31695:	6a 0d                	push   $0xd
   31697:	ff 75 08             	push   0x8(%ebp)
   3169a:	6a 02                	push   $0x2
   3169c:	e8 1e 10 00 00       	call   326bf <parseArgs>
   316a1:	83 c4 20             	add    $0x20,%esp
   316a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	switch( argc ) {
   316a7:	83 7d f0 02          	cmpl   $0x2,-0x10(%ebp)
   316ab:	75 11                	jne    316be <progQ+0x74>
	case 2:	ch = argv[1][0];
   316ad:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   316b3:	0f b6 00             	movzbl (%eax),%eax
   316b6:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   316b9:	e9 9e 00 00 00       	jmp    3175c <progQ+0x112>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   316be:	8b 85 58 ff ff ff    	mov    -0xa8(%ebp),%eax
   316c4:	ff 75 f0             	push   -0x10(%ebp)
   316c7:	50                   	push   %eax
   316c8:	68 b4 44 03 00       	push   $0x344b4
   316cd:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   316d3:	50                   	push   %eax
   316d4:	e8 f8 13 00 00       	call   32ad1 <sprint>
   316d9:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   316dc:	83 ec 0c             	sub    $0xc,%esp
   316df:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   316e5:	50                   	push   %eax
   316e6:	e8 67 12 00 00       	call   32952 <cwrites>
   316eb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   316ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   316f5:	eb 4d                	jmp    31744 <progQ+0xfa>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   316f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   316fa:	8b 84 85 58 ff ff ff 	mov    -0xa8(%ebp,%eax,4),%eax
   31701:	85 c0                	test   %eax,%eax
   31703:	74 0c                	je     31711 <progQ+0xc7>
   31705:	8b 45 f4             	mov    -0xc(%ebp),%eax
   31708:	8b 84 85 58 ff ff ff 	mov    -0xa8(%ebp,%eax,4),%eax
   3170f:	eb 05                	jmp    31716 <progQ+0xcc>
   31711:	b8 c8 44 03 00       	mov    $0x344c8,%eax
   31716:	83 ec 04             	sub    $0x4,%esp
   31719:	50                   	push   %eax
   3171a:	68 cf 44 03 00       	push   $0x344cf
   3171f:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   31725:	50                   	push   %eax
   31726:	e8 a6 13 00 00       	call   32ad1 <sprint>
   3172b:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   3172e:	83 ec 0c             	sub    $0xc,%esp
   31731:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   31737:	50                   	push   %eax
   31738:	e8 15 12 00 00       	call   32952 <cwrites>
   3173d:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   31740:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   31744:	8b 45 f4             	mov    -0xc(%ebp),%eax
   31747:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   3174a:	7e ab                	jle    316f7 <progQ+0xad>
			}
			cwrites( "\n" );
   3174c:	83 ec 0c             	sub    $0xc,%esp
   3174f:	68 d3 44 03 00       	push   $0x344d3
   31754:	e8 f9 11 00 00       	call   32952 <cwrites>
   31759:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   3175c:	83 ec 04             	sub    $0x4,%esp
   3175f:	6a 01                	push   $0x1
   31761:	8d 45 ef             	lea    -0x11(%ebp),%eax
   31764:	50                   	push   %eax
   31765:	6a 01                	push   $0x1
   31767:	e8 bf 12 00 00       	call   32a2b <write>
   3176c:	83 c4 10             	add    $0x10,%esp

	// try something weird
	bogus();
   3176f:	e8 df 12 00 00       	call   32a53 <bogus>

	// should not have come back here!
	sprint( buf, "!!!!! %c returned from bogus syscall!?!?!\n", ch );
   31774:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   31778:	0f be c0             	movsbl %al,%eax
   3177b:	83 ec 04             	sub    $0x4,%esp
   3177e:	50                   	push   %eax
   3177f:	68 d8 44 03 00       	push   $0x344d8
   31784:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   3178a:	50                   	push   %eax
   3178b:	e8 41 13 00 00       	call   32ad1 <sprint>
   31790:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   31793:	83 ec 0c             	sub    $0xc,%esp
   31796:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   3179c:	50                   	push   %eax
   3179d:	e8 b0 11 00 00       	call   32952 <cwrites>
   317a2:	83 c4 10             	add    $0x10,%esp

	exit( 1 );
   317a5:	83 ec 0c             	sub    $0xc,%esp
   317a8:	6a 01                	push   $0x1
   317aa:	e8 54 12 00 00       	call   32a03 <exit>
   317af:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   317b2:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   317b7:	c9                   	leave  
   317b8:	c3                   	ret    

000317b9 <progR>:
**	 where x is the ID character
**		   n is the sequence number of the initial incarnation
**		   s is the initial delay time (defaults to 10)
*/

USERMAIN( progR ) {
   317b9:	55                   	push   %ebp
   317ba:	89 e5                	mov    %esp,%ebp
   317bc:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char ch = 'r';	// default character to print
   317c2:	c6 45 f7 72          	movb   $0x72,-0x9(%ebp)
	int delay = 10;	// initial delay count
   317c6:	c7 45 f0 0a 00 00 00 	movl   $0xa,-0x10(%ebp)
	int seq = 99;	// my sequence number
   317cd:	c7 45 ec 63 00 00 00 	movl   $0x63,-0x14(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progR" );
   317d4:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   317db:	00 00 00 
   317de:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   317e5:	00 00 00 
   317e8:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   317ef:	00 00 00 
   317f2:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   317f9:	00 00 00 
   317fc:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   31803:	00 00 00 
   31806:	83 ec 0c             	sub    $0xc,%esp
   31809:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   3180f:	50                   	push   %eax
   31810:	6a 05                	push   $0x5
   31812:	6a 0d                	push   $0xd
   31814:	ff 75 08             	push   0x8(%ebp)
   31817:	6a 04                	push   $0x4
   31819:	e8 a1 0e 00 00       	call   326bf <parseArgs>
   3181e:	83 c4 20             	add    $0x20,%esp
   31821:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch( argc ) {
   31824:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   31828:	74 14                	je     3183e <progR+0x85>
   3182a:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   3182e:	7f 4d                	jg     3187d <progR+0xc4>
   31830:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
   31834:	74 36                	je     3186c <progR+0xb3>
   31836:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
   3183a:	74 19                	je     31855 <progR+0x9c>
   3183c:	eb 3f                	jmp    3187d <progR+0xc4>
	case 4:	delay = str2int( argv[3], 10 );
   3183e:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
   31844:	83 ec 08             	sub    $0x8,%esp
   31847:	6a 0a                	push   $0xa
   31849:	50                   	push   %eax
   3184a:	e8 f7 14 00 00       	call   32d46 <str2int>
   3184f:	83 c4 10             	add    $0x10,%esp
   31852:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	seq = str2int( argv[2], 10 );
   31855:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   3185b:	83 ec 08             	sub    $0x8,%esp
   3185e:	6a 0a                	push   $0xa
   31860:	50                   	push   %eax
   31861:	e8 e0 14 00 00       	call   32d46 <str2int>
   31866:	83 c4 10             	add    $0x10,%esp
   31869:	89 45 ec             	mov    %eax,-0x14(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   3186c:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   31872:	0f b6 00             	movzbl (%eax),%eax
   31875:	88 45 f7             	mov    %al,-0x9(%ebp)
			break;
   31878:	e9 9e 00 00 00       	jmp    3191b <progR+0x162>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   3187d:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   31883:	ff 75 e4             	push   -0x1c(%ebp)
   31886:	50                   	push   %eax
   31887:	68 03 45 03 00       	push   $0x34503
   3188c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   31892:	50                   	push   %eax
   31893:	e8 39 12 00 00       	call   32ad1 <sprint>
   31898:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   3189b:	83 ec 0c             	sub    $0xc,%esp
   3189e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   318a4:	50                   	push   %eax
   318a5:	e8 a8 10 00 00       	call   32952 <cwrites>
   318aa:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   318ad:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   318b4:	eb 4d                	jmp    31903 <progR+0x14a>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   318b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
   318b9:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   318c0:	85 c0                	test   %eax,%eax
   318c2:	74 0c                	je     318d0 <progR+0x117>
   318c4:	8b 45 e8             	mov    -0x18(%ebp),%eax
   318c7:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   318ce:	eb 05                	jmp    318d5 <progR+0x11c>
   318d0:	b8 17 45 03 00       	mov    $0x34517,%eax
   318d5:	83 ec 04             	sub    $0x4,%esp
   318d8:	50                   	push   %eax
   318d9:	68 1e 45 03 00       	push   $0x3451e
   318de:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   318e4:	50                   	push   %eax
   318e5:	e8 e7 11 00 00       	call   32ad1 <sprint>
   318ea:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   318ed:	83 ec 0c             	sub    $0xc,%esp
   318f0:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   318f6:	50                   	push   %eax
   318f7:	e8 56 10 00 00       	call   32952 <cwrites>
   318fc:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   318ff:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   31903:	8b 45 e8             	mov    -0x18(%ebp),%eax
   31906:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
   31909:	7e ab                	jle    318b6 <progR+0xfd>
			}
			cwrites( "\n" );
   3190b:	83 ec 0c             	sub    $0xc,%esp
   3190e:	68 22 45 03 00       	push   $0x34522
   31913:	e8 3a 10 00 00       	call   32952 <cwrites>
   31918:	83 c4 10             	add    $0x10,%esp
	pid_t pid;

 restart:

	// announce our presence
	pid = getpid();
   3191b:	e8 1b 11 00 00       	call   32a3b <getpid>
   31920:	89 45 e0             	mov    %eax,-0x20(%ebp)

	sprint( buf, " %c[%d,%d]", ch, seq, pid );
   31923:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   31927:	83 ec 0c             	sub    $0xc,%esp
   3192a:	ff 75 e0             	push   -0x20(%ebp)
   3192d:	ff 75 ec             	push   -0x14(%ebp)
   31930:	50                   	push   %eax
   31931:	68 24 45 03 00       	push   $0x34524
   31936:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3193c:	50                   	push   %eax
   3193d:	e8 8f 11 00 00       	call   32ad1 <sprint>
   31942:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   31945:	83 ec 0c             	sub    $0xc,%esp
   31948:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3194e:	50                   	push   %eax
   3194f:	e8 67 10 00 00       	call   329bb <swrites>
   31954:	83 c4 10             	add    $0x10,%esp

	sleep( SEC_TO_MS(delay) );
   31957:	8b 45 f0             	mov    -0x10(%ebp),%eax
   3195a:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   31960:	83 ec 0c             	sub    $0xc,%esp
   31963:	50                   	push   %eax
   31964:	e8 ca 10 00 00       	call   32a33 <sleep>
   31969:	83 c4 10             	add    $0x10,%esp

	// create the next child in sequence
	if( seq < 5 ) {
   3196c:	83 7d ec 04          	cmpl   $0x4,-0x14(%ebp)
   31970:	7f 6c                	jg     319de <progR+0x225>
		++seq;
   31972:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
		pid_t n = fork( PRIO_INHERIT );
   31976:	83 ec 0c             	sub    $0xc,%esp
   31979:	68 80 00 00 00       	push   $0x80
   3197e:	e8 90 10 00 00       	call   32a13 <fork>
   31983:	83 c4 10             	add    $0x10,%esp
   31986:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch( n ) {
   31989:	83 7d dc ff          	cmpl   $0xffffffff,-0x24(%ebp)
   3198d:	74 08                	je     31997 <progR+0x1de>
   3198f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   31993:	74 86                	je     3191b <progR+0x162>
   31995:	eb 2e                	jmp    319c5 <progR+0x20c>
		case -1:
			// failure?
			sprint( buf, "** R[%d] fork code %d\n", pid, n );
   31997:	ff 75 dc             	push   -0x24(%ebp)
   3199a:	ff 75 e0             	push   -0x20(%ebp)
   3199d:	68 2f 45 03 00       	push   $0x3452f
   319a2:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   319a8:	50                   	push   %eax
   319a9:	e8 23 11 00 00       	call   32ad1 <sprint>
   319ae:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   319b1:	83 ec 0c             	sub    $0xc,%esp
   319b4:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   319ba:	50                   	push   %eax
   319bb:	e8 92 0f 00 00       	call   32952 <cwrites>
   319c0:	83 c4 10             	add    $0x10,%esp
			break;
   319c3:	eb 19                	jmp    319de <progR+0x225>
		case 0:
			// child
			goto restart;
		default:
			// parent
			--seq;
   319c5:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
			sleep( SEC_TO_MS(delay) );
   319c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
   319cc:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   319d2:	83 ec 0c             	sub    $0xc,%esp
   319d5:	50                   	push   %eax
   319d6:	e8 58 10 00 00       	call   32a33 <sleep>
   319db:	83 c4 10             	add    $0x10,%esp
		}
	}

	// final report - PPID may change, but PID and seq shouldn't
	pid = getpid();
   319de:	e8 58 10 00 00       	call   32a3b <getpid>
   319e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	sprint( buf, " %c[%d,%d]", ch, seq, pid );
   319e6:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   319ea:	83 ec 0c             	sub    $0xc,%esp
   319ed:	ff 75 e0             	push   -0x20(%ebp)
   319f0:	ff 75 ec             	push   -0x14(%ebp)
   319f3:	50                   	push   %eax
   319f4:	68 24 45 03 00       	push   $0x34524
   319f9:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   319ff:	50                   	push   %eax
   31a00:	e8 cc 10 00 00       	call   32ad1 <sprint>
   31a05:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   31a08:	83 ec 0c             	sub    $0xc,%esp
   31a0b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   31a11:	50                   	push   %eax
   31a12:	e8 a4 0f 00 00       	call   329bb <swrites>
   31a17:	83 c4 10             	add    $0x10,%esp

	exit( 0 );
   31a1a:	83 ec 0c             	sub    $0xc,%esp
   31a1d:	6a 00                	push   $0x0
   31a1f:	e8 df 0f 00 00       	call   32a03 <exit>
   31a24:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   31a27:	b8 2a 00 00 00       	mov    $0x2a,%eax

}
   31a2c:	c9                   	leave  
   31a2d:	c3                   	ret    

00031a2e <progS>:
** Invoked as:  progS  x  [ s ]
**	 where x is the ID character
**		   s is the sleep time (defaults to 20)
*/

USERMAIN( progS ) {
   31a2e:	55                   	push   %ebp
   31a2f:	89 e5                	mov    %esp,%ebp
   31a31:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char ch = 's';	  // default character to print
   31a37:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
	int nap = 20;	  // nap time
   31a3b:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progS" );
   31a42:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   31a49:	00 00 00 
   31a4c:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   31a53:	00 00 00 
   31a56:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   31a5d:	00 00 00 
   31a60:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
   31a67:	00 00 00 
   31a6a:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
   31a71:	00 00 00 
   31a74:	83 ec 0c             	sub    $0xc,%esp
   31a77:	8d 85 50 ff ff ff    	lea    -0xb0(%ebp),%eax
   31a7d:	50                   	push   %eax
   31a7e:	6a 05                	push   $0x5
   31a80:	6a 0d                	push   $0xd
   31a82:	ff 75 08             	push   0x8(%ebp)
   31a85:	6a 03                	push   $0x3
   31a87:	e8 33 0c 00 00       	call   326bf <parseArgs>
   31a8c:	83 c4 20             	add    $0x20,%esp
   31a8f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	const char *name = argv[0];
   31a92:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   31a98:	89 45 e8             	mov    %eax,-0x18(%ebp)

	switch( argc ) {
   31a9b:	83 7d ec 02          	cmpl   $0x2,-0x14(%ebp)
   31a9f:	74 1d                	je     31abe <progS+0x90>
   31aa1:	83 7d ec 03          	cmpl   $0x3,-0x14(%ebp)
   31aa5:	75 28                	jne    31acf <progS+0xa1>
	case 3:	nap = str2int( argv[2], 10 );
   31aa7:	8b 85 58 ff ff ff    	mov    -0xa8(%ebp),%eax
   31aad:	83 ec 08             	sub    $0x8,%esp
   31ab0:	6a 0a                	push   $0xa
   31ab2:	50                   	push   %eax
   31ab3:	e8 8e 12 00 00       	call   32d46 <str2int>
   31ab8:	83 c4 10             	add    $0x10,%esp
   31abb:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   31abe:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
   31ac4:	0f b6 00             	movzbl (%eax),%eax
   31ac7:	88 45 e7             	mov    %al,-0x19(%ebp)
			break;
   31aca:	e9 9a 00 00 00       	jmp    31b69 <progS+0x13b>
	default:
			sprint( buf, "%s: argc %d, args: ", name, argc );
   31acf:	ff 75 ec             	push   -0x14(%ebp)
   31ad2:	ff 75 e8             	push   -0x18(%ebp)
   31ad5:	68 46 45 03 00       	push   $0x34546
   31ada:	8d 85 67 ff ff ff    	lea    -0x99(%ebp),%eax
   31ae0:	50                   	push   %eax
   31ae1:	e8 eb 0f 00 00       	call   32ad1 <sprint>
   31ae6:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   31ae9:	83 ec 0c             	sub    $0xc,%esp
   31aec:	8d 85 67 ff ff ff    	lea    -0x99(%ebp),%eax
   31af2:	50                   	push   %eax
   31af3:	e8 5a 0e 00 00       	call   32952 <cwrites>
   31af8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   31afb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   31b02:	eb 4d                	jmp    31b51 <progS+0x123>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   31b04:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31b07:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
   31b0e:	85 c0                	test   %eax,%eax
   31b10:	74 0c                	je     31b1e <progS+0xf0>
   31b12:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31b15:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
   31b1c:	eb 05                	jmp    31b23 <progS+0xf5>
   31b1e:	b8 5a 45 03 00       	mov    $0x3455a,%eax
   31b23:	83 ec 04             	sub    $0x4,%esp
   31b26:	50                   	push   %eax
   31b27:	68 61 45 03 00       	push   $0x34561
   31b2c:	8d 85 67 ff ff ff    	lea    -0x99(%ebp),%eax
   31b32:	50                   	push   %eax
   31b33:	e8 99 0f 00 00       	call   32ad1 <sprint>
   31b38:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   31b3b:	83 ec 0c             	sub    $0xc,%esp
   31b3e:	8d 85 67 ff ff ff    	lea    -0x99(%ebp),%eax
   31b44:	50                   	push   %eax
   31b45:	e8 08 0e 00 00       	call   32952 <cwrites>
   31b4a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   31b4d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   31b51:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31b54:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   31b57:	7e ab                	jle    31b04 <progS+0xd6>
			}
			cwrites( "\n" );
   31b59:	83 ec 0c             	sub    $0xc,%esp
   31b5c:	68 65 45 03 00       	push   $0x34565
   31b61:	e8 ec 0d 00 00       	call   32952 <cwrites>
   31b66:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   31b69:	83 ec 04             	sub    $0x4,%esp
   31b6c:	6a 01                	push   $0x1
   31b6e:	8d 45 e7             	lea    -0x19(%ebp),%eax
   31b71:	50                   	push   %eax
   31b72:	6a 01                	push   $0x1
   31b74:	e8 b2 0e 00 00       	call   32a2b <write>
   31b79:	83 c4 10             	add    $0x10,%esp

	sprint( buf, "%s sleeping %d(%d)\n", name, nap, SEC_TO_MS(nap) );
   31b7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   31b7f:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   31b85:	83 ec 0c             	sub    $0xc,%esp
   31b88:	50                   	push   %eax
   31b89:	ff 75 f4             	push   -0xc(%ebp)
   31b8c:	ff 75 e8             	push   -0x18(%ebp)
   31b8f:	68 67 45 03 00       	push   $0x34567
   31b94:	8d 85 67 ff ff ff    	lea    -0x99(%ebp),%eax
   31b9a:	50                   	push   %eax
   31b9b:	e8 31 0f 00 00       	call   32ad1 <sprint>
   31ba0:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   31ba3:	83 ec 0c             	sub    $0xc,%esp
   31ba6:	8d 85 67 ff ff ff    	lea    -0x99(%ebp),%eax
   31bac:	50                   	push   %eax
   31bad:	e8 a0 0d 00 00       	call   32952 <cwrites>
   31bb2:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		sleep( SEC_TO_MS(nap) );
   31bb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   31bb8:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   31bbe:	83 ec 0c             	sub    $0xc,%esp
   31bc1:	50                   	push   %eax
   31bc2:	e8 6c 0e 00 00       	call   32a33 <sleep>
   31bc7:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   31bca:	83 ec 04             	sub    $0x4,%esp
   31bcd:	6a 01                	push   $0x1
   31bcf:	8d 45 e7             	lea    -0x19(%ebp),%eax
   31bd2:	50                   	push   %eax
   31bd3:	6a 01                	push   $0x1
   31bd5:	e8 51 0e 00 00       	call   32a2b <write>
   31bda:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   31bdd:	eb d6                	jmp    31bb5 <progS+0x187>

00031bdf <progTUV>:

#ifndef MAX_CHILDREN
#define MAX_CHILDREN	50
#endif

USERMAIN( progTUV ) {
   31bdf:	55                   	push   %ebp
   31be0:	89 e5                	mov    %esp,%ebp
   31be2:	81 ec a8 01 00 00    	sub    $0x1a8,%esp
	int count = 3;			// default child count
   31be8:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = '6';			// default character to print
   31bef:	c6 45 c7 36          	movb   $0x36,-0x39(%ebp)
	int nap = 8;			// nap time
   31bf3:	c7 45 d8 08 00 00 00 	movl   $0x8,-0x28(%ebp)
	char buf[128];
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   31bfa:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	char ch2[] = "*?*";
   31c01:	c7 85 78 fe ff ff 2a 	movl   $0x2a3f2a,-0x188(%ebp)
   31c08:	3f 2a 00 

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progTUV" );
   31c0b:	c7 85 64 fe ff ff 00 	movl   $0x0,-0x19c(%ebp)
   31c12:	00 00 00 
   31c15:	c7 85 68 fe ff ff 00 	movl   $0x0,-0x198(%ebp)
   31c1c:	00 00 00 
   31c1f:	c7 85 6c fe ff ff 00 	movl   $0x0,-0x194(%ebp)
   31c26:	00 00 00 
   31c29:	c7 85 70 fe ff ff 00 	movl   $0x0,-0x190(%ebp)
   31c30:	00 00 00 
   31c33:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
   31c3a:	00 00 00 
   31c3d:	83 ec 0c             	sub    $0xc,%esp
   31c40:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
   31c46:	50                   	push   %eax
   31c47:	6a 05                	push   $0x5
   31c49:	6a 0d                	push   $0xd
   31c4b:	ff 75 08             	push   0x8(%ebp)
   31c4e:	6a 03                	push   $0x3
   31c50:	e8 6a 0a 00 00       	call   326bf <parseArgs>
   31c55:	83 c4 20             	add    $0x20,%esp
   31c58:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	switch( argc ) {
   31c5b:	83 7d d4 02          	cmpl   $0x2,-0x2c(%ebp)
   31c5f:	74 1d                	je     31c7e <progTUV+0x9f>
   31c61:	83 7d d4 03          	cmpl   $0x3,-0x2c(%ebp)
   31c65:	75 28                	jne    31c8f <progTUV+0xb0>
	case 3:	count = str2int( argv[2], 10 );
   31c67:	8b 85 6c fe ff ff    	mov    -0x194(%ebp),%eax
   31c6d:	83 ec 08             	sub    $0x8,%esp
   31c70:	6a 0a                	push   $0xa
   31c72:	50                   	push   %eax
   31c73:	e8 ce 10 00 00       	call   32d46 <str2int>
   31c78:	83 c4 10             	add    $0x10,%esp
   31c7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   31c7e:	8b 85 68 fe ff ff    	mov    -0x198(%ebp),%eax
   31c84:	0f b6 00             	movzbl (%eax),%eax
   31c87:	88 45 c7             	mov    %al,-0x39(%ebp)
			break;
   31c8a:	e9 9e 00 00 00       	jmp    31d2d <progTUV+0x14e>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   31c8f:	8b 85 64 fe ff ff    	mov    -0x19c(%ebp),%eax
   31c95:	ff 75 d4             	push   -0x2c(%ebp)
   31c98:	50                   	push   %eax
   31c99:	68 7c 45 03 00       	push   $0x3457c
   31c9e:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31ca4:	50                   	push   %eax
   31ca5:	e8 27 0e 00 00       	call   32ad1 <sprint>
   31caa:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   31cad:	83 ec 0c             	sub    $0xc,%esp
   31cb0:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31cb6:	50                   	push   %eax
   31cb7:	e8 96 0c 00 00       	call   32952 <cwrites>
   31cbc:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   31cbf:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   31cc6:	eb 4d                	jmp    31d15 <progTUV+0x136>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   31cc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31ccb:	8b 84 85 64 fe ff ff 	mov    -0x19c(%ebp,%eax,4),%eax
   31cd2:	85 c0                	test   %eax,%eax
   31cd4:	74 0c                	je     31ce2 <progTUV+0x103>
   31cd6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31cd9:	8b 84 85 64 fe ff ff 	mov    -0x19c(%ebp,%eax,4),%eax
   31ce0:	eb 05                	jmp    31ce7 <progTUV+0x108>
   31ce2:	b8 90 45 03 00       	mov    $0x34590,%eax
   31ce7:	83 ec 04             	sub    $0x4,%esp
   31cea:	50                   	push   %eax
   31ceb:	68 97 45 03 00       	push   $0x34597
   31cf0:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31cf6:	50                   	push   %eax
   31cf7:	e8 d5 0d 00 00       	call   32ad1 <sprint>
   31cfc:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   31cff:	83 ec 0c             	sub    $0xc,%esp
   31d02:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31d08:	50                   	push   %eax
   31d09:	e8 44 0c 00 00       	call   32952 <cwrites>
   31d0e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   31d11:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   31d15:	8b 45 ec             	mov    -0x14(%ebp),%eax
   31d18:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
   31d1b:	7e ab                	jle    31cc8 <progTUV+0xe9>
			}
			cwrites( "\n" );
   31d1d:	83 ec 0c             	sub    $0xc,%esp
   31d20:	68 9b 45 03 00       	push   $0x3459b
   31d25:	e8 28 0c 00 00       	call   32952 <cwrites>
   31d2a:	83 c4 10             	add    $0x10,%esp
	}

	// fix the secondary output message (for indicating errors)
	ch2[1] = ch;
   31d2d:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   31d31:	88 85 79 fe ff ff    	mov    %al,-0x187(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   31d37:	83 ec 04             	sub    $0x4,%esp
   31d3a:	6a 01                	push   $0x1
   31d3c:	8d 45 c7             	lea    -0x39(%ebp),%eax
   31d3f:	50                   	push   %eax
   31d40:	6a 01                	push   $0x1
   31d42:	e8 e4 0c 00 00       	call   32a2b <write>
   31d47:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	char *argw = "progW\rW\r10\r5";
   31d4a:	c7 45 d0 9d 45 03 00 	movl   $0x3459d,-0x30(%ebp)

	for( int i = 0; i < count; ++i ) {
   31d51:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   31d58:	eb 48                	jmp    31da2 <progTUV+0x1c3>
		int whom = spawn( (uint32_t) progW, argw );
   31d5a:	b8 14 1f 03 00       	mov    $0x31f14,%eax
   31d5f:	83 ec 08             	sub    $0x8,%esp
   31d62:	ff 75 d0             	push   -0x30(%ebp)
   31d65:	50                   	push   %eax
   31d66:	e8 fd 0a 00 00       	call   32868 <spawn>
   31d6b:	83 c4 10             	add    $0x10,%esp
   31d6e:	89 45 c8             	mov    %eax,-0x38(%ebp)
		if( whom < 0 ) {
   31d71:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
   31d75:	79 14                	jns    31d8b <progTUV+0x1ac>
			swrites( ch2 );
   31d77:	83 ec 0c             	sub    $0xc,%esp
   31d7a:	8d 85 78 fe ff ff    	lea    -0x188(%ebp),%eax
   31d80:	50                   	push   %eax
   31d81:	e8 35 0c 00 00       	call   329bb <swrites>
   31d86:	83 c4 10             	add    $0x10,%esp
   31d89:	eb 13                	jmp    31d9e <progTUV+0x1bf>
		} else {
			children[nkids++] = whom;
   31d8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   31d8e:	8d 50 01             	lea    0x1(%eax),%edx
   31d91:	89 55 f0             	mov    %edx,-0x10(%ebp)
   31d94:	8b 55 c8             	mov    -0x38(%ebp),%edx
   31d97:	89 94 85 7c fe ff ff 	mov    %edx,-0x184(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   31d9e:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   31da2:	8b 45 e8             	mov    -0x18(%ebp),%eax
   31da5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   31da8:	7c b0                	jl     31d5a <progTUV+0x17b>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   31daa:	8b 45 d8             	mov    -0x28(%ebp),%eax
   31dad:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   31db3:	83 ec 0c             	sub    $0xc,%esp
   31db6:	50                   	push   %eax
   31db7:	e8 77 0c 00 00       	call   32a33 <sleep>
   31dbc:	83 c4 10             	add    $0x10,%esp

	// collect exit status information

	// current child index
	int n = 0;
   31dbf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

	do {
		pid_t this;
		int32_t status;

		status = 0xcafe;
   31dc6:	c7 85 60 fe ff ff fe 	movl   $0xcafe,-0x1a0(%ebp)
   31dcd:	ca 00 00 
		this = wait( &status );
   31dd0:	83 ec 0c             	sub    $0xc,%esp
   31dd3:	8d 85 60 fe ff ff    	lea    -0x1a0(%ebp),%eax
   31dd9:	50                   	push   %eax
   31dda:	e8 2c 0c 00 00       	call   32a0b <wait>
   31ddf:	83 c4 10             	add    $0x10,%esp
   31de2:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// what was the result?
		if( this < 1 ) {
   31de5:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
   31de9:	7f 61                	jg     31e4c <progTUV+0x26d>

			// uh-oh - something went wrong

			// "no children" means we're all done
			if( this != S_NO_CHILD ) {
   31deb:	83 7d cc fc          	cmpl   $0xfffffffc,-0x34(%ebp)
   31def:	74 37                	je     31e28 <progTUV+0x249>
				sprint( buf, "!! %c: wait() ret %d status %d (%x)\n",
   31df1:	8b 85 60 fe ff ff    	mov    -0x1a0(%ebp),%eax
   31df7:	89 c1                	mov    %eax,%ecx
   31df9:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   31dff:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   31e03:	0f be c0             	movsbl %al,%eax
   31e06:	83 ec 08             	sub    $0x8,%esp
   31e09:	51                   	push   %ecx
   31e0a:	52                   	push   %edx
   31e0b:	ff 75 cc             	push   -0x34(%ebp)
   31e0e:	50                   	push   %eax
   31e0f:	68 ac 45 03 00       	push   $0x345ac
   31e14:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31e1a:	50                   	push   %eax
   31e1b:	e8 b1 0c 00 00       	call   32ad1 <sprint>
   31e20:	83 c4 20             	add    $0x20,%esp
			} else {
				sprint( buf, "!! %c: no children\n", ch );
			}

			// regardless, we're outta here
			break;
   31e23:	e9 d8 00 00 00       	jmp    31f00 <progTUV+0x321>
				sprint( buf, "!! %c: no children\n", ch );
   31e28:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   31e2c:	0f be c0             	movsbl %al,%eax
   31e2f:	83 ec 04             	sub    $0x4,%esp
   31e32:	50                   	push   %eax
   31e33:	68 d1 45 03 00       	push   $0x345d1
   31e38:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31e3e:	50                   	push   %eax
   31e3f:	e8 8d 0c 00 00       	call   32ad1 <sprint>
   31e44:	83 c4 10             	add    $0x10,%esp
   31e47:	e9 b4 00 00 00       	jmp    31f00 <progTUV+0x321>

		} else {

			// locate the child
			int ix = -1;
   31e4c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)

			int i;
			for( i = 0; i < nkids; ++i ) {
   31e53:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
   31e5a:	eb 1d                	jmp    31e79 <progTUV+0x29a>
				if( children[i] == this ) {
   31e5c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   31e5f:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   31e66:	8b 45 cc             	mov    -0x34(%ebp),%eax
   31e69:	39 c2                	cmp    %eax,%edx
   31e6b:	75 08                	jne    31e75 <progTUV+0x296>
					ix = i;
   31e6d:	8b 45 dc             	mov    -0x24(%ebp),%eax
   31e70:	89 45 e0             	mov    %eax,-0x20(%ebp)
					break;
   31e73:	eb 0c                	jmp    31e81 <progTUV+0x2a2>
			for( i = 0; i < nkids; ++i ) {
   31e75:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
   31e79:	8b 45 dc             	mov    -0x24(%ebp),%eax
   31e7c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   31e7f:	7c db                	jl     31e5c <progTUV+0x27d>
				}
			}

			// if ix == -1, the PID we received isn't in our list of children

			if( ix < 0 ) {
   31e81:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   31e85:	79 2b                	jns    31eb2 <progTUV+0x2d3>

				// didn't find an entry for this PID???
				sprint( buf, "!! %c: child PID %d status %d, NOT FOUND\n",
   31e87:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   31e8d:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   31e91:	0f be c0             	movsbl %al,%eax
   31e94:	83 ec 0c             	sub    $0xc,%esp
   31e97:	52                   	push   %edx
   31e98:	ff 75 cc             	push   -0x34(%ebp)
   31e9b:	50                   	push   %eax
   31e9c:	68 e8 45 03 00       	push   $0x345e8
   31ea1:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31ea7:	50                   	push   %eax
   31ea8:	e8 24 0c 00 00       	call   32ad1 <sprint>
   31ead:	83 c4 20             	add    $0x20,%esp
   31eb0:	eb 2c                	jmp    31ede <progTUV+0x2ff>
						ch, this, status );

			} else {

				// found this PID in our list of children
				sprint( buf, "== %c: child %d (%d) status %d\n",
   31eb2:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   31eb8:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   31ebc:	0f be c0             	movsbl %al,%eax
   31ebf:	83 ec 08             	sub    $0x8,%esp
   31ec2:	52                   	push   %edx
   31ec3:	ff 75 cc             	push   -0x34(%ebp)
   31ec6:	ff 75 e0             	push   -0x20(%ebp)
   31ec9:	50                   	push   %eax
   31eca:	68 14 46 03 00       	push   $0x34614
   31ecf:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31ed5:	50                   	push   %eax
   31ed6:	e8 f6 0b 00 00       	call   32ad1 <sprint>
   31edb:	83 c4 20             	add    $0x20,%esp
						ch, ix, this, status );
			}

		}

		cwrites( buf );
   31ede:	83 ec 0c             	sub    $0xc,%esp
   31ee1:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   31ee7:	50                   	push   %eax
   31ee8:	e8 65 0a 00 00       	call   32952 <cwrites>
   31eed:	83 c4 10             	add    $0x10,%esp

		++n;
   31ef0:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)

	} while( n < nkids );
   31ef4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   31ef7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   31efa:	0f 8c c6 fe ff ff    	jl     31dc6 <progTUV+0x1e7>

	exit( 0 );
   31f00:	83 ec 0c             	sub    $0xc,%esp
   31f03:	6a 00                	push   $0x0
   31f05:	e8 f9 0a 00 00       	call   32a03 <exit>
   31f0a:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   31f0d:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   31f12:	c9                   	leave  
   31f13:	c3                   	ret    

00031f14 <progW>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 20)
**		   s is the sleep time (defaults to 3 seconds)
*/

USERMAIN( progW ) {
   31f14:	55                   	push   %ebp
   31f15:	89 e5                	mov    %esp,%ebp
   31f17:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	int count = 20;	  // default iteration count
   31f1d:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'w';	  // default character to print
   31f24:	c6 45 db 77          	movb   $0x77,-0x25(%ebp)
	int nap = 3;	  // nap length
   31f28:	c7 45 f0 03 00 00 00 	movl   $0x3,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progW" );
   31f2f:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
   31f36:	00 00 00 
   31f39:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   31f40:	00 00 00 
   31f43:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   31f4a:	00 00 00 
   31f4d:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   31f54:	00 00 00 
   31f57:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   31f5e:	00 00 00 
   31f61:	83 ec 0c             	sub    $0xc,%esp
   31f64:	8d 85 44 ff ff ff    	lea    -0xbc(%ebp),%eax
   31f6a:	50                   	push   %eax
   31f6b:	6a 05                	push   $0x5
   31f6d:	6a 0d                	push   $0xd
   31f6f:	ff 75 08             	push   0x8(%ebp)
   31f72:	6a 04                	push   $0x4
   31f74:	e8 46 07 00 00       	call   326bf <parseArgs>
   31f79:	83 c4 20             	add    $0x20,%esp
   31f7c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch( argc ) {
   31f7f:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   31f83:	74 14                	je     31f99 <progW+0x85>
   31f85:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
   31f89:	7f 4d                	jg     31fd8 <progW+0xc4>
   31f8b:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
   31f8f:	74 36                	je     31fc7 <progW+0xb3>
   31f91:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
   31f95:	74 19                	je     31fb0 <progW+0x9c>
   31f97:	eb 3f                	jmp    31fd8 <progW+0xc4>
	case 4:	nap = str2int( argv[3], 10 );
   31f99:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   31f9f:	83 ec 08             	sub    $0x8,%esp
   31fa2:	6a 0a                	push   $0xa
   31fa4:	50                   	push   %eax
   31fa5:	e8 9c 0d 00 00       	call   32d46 <str2int>
   31faa:	83 c4 10             	add    $0x10,%esp
   31fad:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = str2int( argv[2], 10 );
   31fb0:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   31fb6:	83 ec 08             	sub    $0x8,%esp
   31fb9:	6a 0a                	push   $0xa
   31fbb:	50                   	push   %eax
   31fbc:	e8 85 0d 00 00       	call   32d46 <str2int>
   31fc1:	83 c4 10             	add    $0x10,%esp
   31fc4:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   31fc7:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   31fcd:	0f b6 00             	movzbl (%eax),%eax
   31fd0:	88 45 db             	mov    %al,-0x25(%ebp)
			break;
   31fd3:	e9 9e 00 00 00       	jmp    32076 <progW+0x162>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   31fd8:	8b 85 44 ff ff ff    	mov    -0xbc(%ebp),%eax
   31fde:	ff 75 e4             	push   -0x1c(%ebp)
   31fe1:	50                   	push   %eax
   31fe2:	68 34 46 03 00       	push   $0x34634
   31fe7:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   31fed:	50                   	push   %eax
   31fee:	e8 de 0a 00 00       	call   32ad1 <sprint>
   31ff3:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   31ff6:	83 ec 0c             	sub    $0xc,%esp
   31ff9:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   31fff:	50                   	push   %eax
   32000:	e8 4d 09 00 00       	call   32952 <cwrites>
   32005:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   32008:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   3200f:	eb 4d                	jmp    3205e <progW+0x14a>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   32011:	8b 45 ec             	mov    -0x14(%ebp),%eax
   32014:	8b 84 85 44 ff ff ff 	mov    -0xbc(%ebp,%eax,4),%eax
   3201b:	85 c0                	test   %eax,%eax
   3201d:	74 0c                	je     3202b <progW+0x117>
   3201f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   32022:	8b 84 85 44 ff ff ff 	mov    -0xbc(%ebp,%eax,4),%eax
   32029:	eb 05                	jmp    32030 <progW+0x11c>
   3202b:	b8 48 46 03 00       	mov    $0x34648,%eax
   32030:	83 ec 04             	sub    $0x4,%esp
   32033:	50                   	push   %eax
   32034:	68 4f 46 03 00       	push   $0x3464f
   32039:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   3203f:	50                   	push   %eax
   32040:	e8 8c 0a 00 00       	call   32ad1 <sprint>
   32045:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   32048:	83 ec 0c             	sub    $0xc,%esp
   3204b:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   32051:	50                   	push   %eax
   32052:	e8 fb 08 00 00       	call   32952 <cwrites>
   32057:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   3205a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   3205e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   32061:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
   32064:	7e ab                	jle    32011 <progW+0xfd>
			}
			cwrites( "\n" );
   32066:	83 ec 0c             	sub    $0xc,%esp
   32069:	68 53 46 03 00       	push   $0x34653
   3206e:	e8 df 08 00 00       	call   32952 <cwrites>
   32073:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	pid_t pid = getpid();
   32076:	e8 c0 09 00 00       	call   32a3b <getpid>
   3207b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	time_t now = gettime();
   3207e:	e8 c0 09 00 00       	call   32a43 <gettime>
   32083:	89 45 dc             	mov    %eax,-0x24(%ebp)
	sprint( buf, " %c[%d,%u]", ch, pid, now );
   32086:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   3208a:	0f be c0             	movsbl %al,%eax
   3208d:	83 ec 0c             	sub    $0xc,%esp
   32090:	ff 75 dc             	push   -0x24(%ebp)
   32093:	ff 75 e0             	push   -0x20(%ebp)
   32096:	50                   	push   %eax
   32097:	68 55 46 03 00       	push   $0x34655
   3209c:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   320a2:	50                   	push   %eax
   320a3:	e8 29 0a 00 00       	call   32ad1 <sprint>
   320a8:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   320ab:	83 ec 0c             	sub    $0xc,%esp
   320ae:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   320b4:	50                   	push   %eax
   320b5:	e8 01 09 00 00       	call   329bb <swrites>
   320ba:	83 c4 10             	add    $0x10,%esp

	write( CHAN_SIO, &ch, 1 );
   320bd:	83 ec 04             	sub    $0x4,%esp
   320c0:	6a 01                	push   $0x1
   320c2:	8d 45 db             	lea    -0x25(%ebp),%eax
   320c5:	50                   	push   %eax
   320c6:	6a 01                	push   $0x1
   320c8:	e8 5e 09 00 00       	call   32a2b <write>
   320cd:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   320d0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   320d7:	eb 58                	jmp    32131 <progW+0x21d>
		now = gettime();
   320d9:	e8 65 09 00 00       	call   32a43 <gettime>
   320de:	89 45 dc             	mov    %eax,-0x24(%ebp)
		sprint( buf, " %c[%d,%u] ", ch, pid, now );
   320e1:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   320e5:	0f be c0             	movsbl %al,%eax
   320e8:	83 ec 0c             	sub    $0xc,%esp
   320eb:	ff 75 dc             	push   -0x24(%ebp)
   320ee:	ff 75 e0             	push   -0x20(%ebp)
   320f1:	50                   	push   %eax
   320f2:	68 60 46 03 00       	push   $0x34660
   320f7:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   320fd:	50                   	push   %eax
   320fe:	e8 ce 09 00 00       	call   32ad1 <sprint>
   32103:	83 c4 20             	add    $0x20,%esp
		swrites( buf );
   32106:	83 ec 0c             	sub    $0xc,%esp
   32109:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   3210f:	50                   	push   %eax
   32110:	e8 a6 08 00 00       	call   329bb <swrites>
   32115:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   32118:	8b 45 f0             	mov    -0x10(%ebp),%eax
   3211b:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   32121:	83 ec 0c             	sub    $0xc,%esp
   32124:	50                   	push   %eax
   32125:	e8 09 09 00 00       	call   32a33 <sleep>
   3212a:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   3212d:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   32131:	8b 45 e8             	mov    -0x18(%ebp),%eax
   32134:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   32137:	7c a0                	jl     320d9 <progW+0x1c5>
	}

	exit( 0 );
   32139:	83 ec 0c             	sub    $0xc,%esp
   3213c:	6a 00                	push   $0x0
   3213e:	e8 c0 08 00 00       	call   32a03 <exit>
   32143:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   32146:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   3214b:	c9                   	leave  
   3214c:	c3                   	ret    

0003214d <progX>:
** Invoked as:  progX  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progX ) {
   3214d:	55                   	push   %ebp
   3214e:	89 e5                	mov    %esp,%ebp
   32150:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	int count = 20;	  // iteration count
   32156:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'x';	  // default character to print
   3215d:	c6 45 f3 78          	movb   $0x78,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progX" );
   32161:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   32168:	00 00 00 
   3216b:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   32172:	00 00 00 
   32175:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   3217c:	00 00 00 
   3217f:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   32186:	00 00 00 
   32189:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   32190:	00 00 00 
   32193:	83 ec 0c             	sub    $0xc,%esp
   32196:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   3219c:	50                   	push   %eax
   3219d:	6a 05                	push   $0x5
   3219f:	6a 0d                	push   $0xd
   321a1:	ff 75 08             	push   0x8(%ebp)
   321a4:	6a 03                	push   $0x3
   321a6:	e8 14 05 00 00       	call   326bf <parseArgs>
   321ab:	83 c4 20             	add    $0x20,%esp
   321ae:	89 45 e0             	mov    %eax,-0x20(%ebp)
	switch( argc ) {
   321b1:	83 7d e0 02          	cmpl   $0x2,-0x20(%ebp)
   321b5:	74 1d                	je     321d4 <progX+0x87>
   321b7:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
   321bb:	75 28                	jne    321e5 <progX+0x98>
	case 3:	count = str2int( argv[2], 10 );
   321bd:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   321c3:	83 ec 08             	sub    $0x8,%esp
   321c6:	6a 0a                	push   $0xa
   321c8:	50                   	push   %eax
   321c9:	e8 78 0b 00 00       	call   32d46 <str2int>
   321ce:	83 c4 10             	add    $0x10,%esp
   321d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   321d4:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   321da:	0f b6 00             	movzbl (%eax),%eax
   321dd:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   321e0:	e9 9e 00 00 00       	jmp    32283 <progX+0x136>
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
   321e5:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
   321eb:	ff 75 e0             	push   -0x20(%ebp)
   321ee:	50                   	push   %eax
   321ef:	68 6c 46 03 00       	push   $0x3466c
   321f4:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   321fa:	50                   	push   %eax
   321fb:	e8 d1 08 00 00       	call   32ad1 <sprint>
   32200:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   32203:	83 ec 0c             	sub    $0xc,%esp
   32206:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3220c:	50                   	push   %eax
   3220d:	e8 40 07 00 00       	call   32952 <cwrites>
   32212:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   32215:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   3221c:	eb 4d                	jmp    3226b <progX+0x11e>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   3221e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   32221:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   32228:	85 c0                	test   %eax,%eax
   3222a:	74 0c                	je     32238 <progX+0xeb>
   3222c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   3222f:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   32236:	eb 05                	jmp    3223d <progX+0xf0>
   32238:	b8 80 46 03 00       	mov    $0x34680,%eax
   3223d:	83 ec 04             	sub    $0x4,%esp
   32240:	50                   	push   %eax
   32241:	68 87 46 03 00       	push   $0x34687
   32246:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3224c:	50                   	push   %eax
   3224d:	e8 7f 08 00 00       	call   32ad1 <sprint>
   32252:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   32255:	83 ec 0c             	sub    $0xc,%esp
   32258:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3225e:	50                   	push   %eax
   3225f:	e8 ee 06 00 00       	call   32952 <cwrites>
   32264:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   32267:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   3226b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   3226e:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   32271:	7e ab                	jle    3221e <progX+0xd1>
			}
			cwrites( "\n" );
   32273:	83 ec 0c             	sub    $0xc,%esp
   32276:	68 8b 46 03 00       	push   $0x3468b
   3227b:	e8 d2 06 00 00       	call   32952 <cwrites>
   32280:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	pid_t pid = getpid();
   32283:	e8 b3 07 00 00       	call   32a3b <getpid>
   32288:	89 45 dc             	mov    %eax,-0x24(%ebp)
	sprint( buf, " %c[%d]", ch, pid );
   3228b:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   3228f:	ff 75 dc             	push   -0x24(%ebp)
   32292:	50                   	push   %eax
   32293:	68 8d 46 03 00       	push   $0x3468d
   32298:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3229e:	50                   	push   %eax
   3229f:	e8 2d 08 00 00       	call   32ad1 <sprint>
   322a4:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   322a7:	83 ec 0c             	sub    $0xc,%esp
   322aa:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   322b0:	50                   	push   %eax
   322b1:	e8 05 07 00 00       	call   329bb <swrites>
   322b6:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   322b9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   322c0:	eb 2c                	jmp    322ee <progX+0x1a1>
		swrites( buf );
   322c2:	83 ec 0c             	sub    $0xc,%esp
   322c5:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   322cb:	50                   	push   %eax
   322cc:	e8 ea 06 00 00       	call   329bb <swrites>
   322d1:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   322d4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   322db:	eb 04                	jmp    322e1 <progX+0x194>
   322dd:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   322e1:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   322e8:	7e f3                	jle    322dd <progX+0x190>
	for( int i = 0; i < count ; ++i ) {
   322ea:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   322ee:	8b 45 e8             	mov    -0x18(%ebp),%eax
   322f1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   322f4:	7c cc                	jl     322c2 <progX+0x175>
	}

	exit( 12 );
   322f6:	83 ec 0c             	sub    $0xc,%esp
   322f9:	6a 0c                	push   $0xc
   322fb:	e8 03 07 00 00       	call   32a03 <exit>
   32300:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   32303:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   32308:	c9                   	leave  
   32309:	c3                   	ret    

0003230a <progY>:
** Invoked as:	progY  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progY ) {
   3230a:	55                   	push   %ebp
   3230b:	89 e5                	mov    %esp,%ebp
   3230d:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	int count = 10;	  // default iteration count
   32313:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'y';	  // default character to print
   3231a:	c6 45 f3 79          	movb   $0x79,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progY" );
   3231e:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   32325:	00 00 00 
   32328:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   3232f:	00 00 00 
   32332:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   32339:	00 00 00 
   3233c:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   32343:	00 00 00 
   32346:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   3234d:	00 00 00 
   32350:	83 ec 0c             	sub    $0xc,%esp
   32353:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   32359:	50                   	push   %eax
   3235a:	6a 05                	push   $0x5
   3235c:	6a 0d                	push   $0xd
   3235e:	ff 75 08             	push   0x8(%ebp)
   32361:	6a 03                	push   $0x3
   32363:	e8 57 03 00 00       	call   326bf <parseArgs>
   32368:	83 c4 20             	add    $0x20,%esp
   3236b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	switch( argc ) {
   3236e:	83 7d e0 02          	cmpl   $0x2,-0x20(%ebp)
   32372:	74 1d                	je     32391 <progY+0x87>
   32374:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
   32378:	75 28                	jne    323a2 <progY+0x98>
	case 3:	count = str2int( argv[2], 10 );
   3237a:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   32380:	83 ec 08             	sub    $0x8,%esp
   32383:	6a 0a                	push   $0xa
   32385:	50                   	push   %eax
   32386:	e8 bb 09 00 00       	call   32d46 <str2int>
   3238b:	83 c4 10             	add    $0x10,%esp
   3238e:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   32391:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   32397:	0f b6 00             	movzbl (%eax),%eax
   3239a:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   3239d:	e9 9a 00 00 00       	jmp    3243c <progY+0x132>
	default:
			sprint( buf, "?: argc %d, args: ", argc );
   323a2:	83 ec 04             	sub    $0x4,%esp
   323a5:	ff 75 e0             	push   -0x20(%ebp)
   323a8:	68 95 46 03 00       	push   $0x34695
   323ad:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   323b3:	50                   	push   %eax
   323b4:	e8 18 07 00 00       	call   32ad1 <sprint>
   323b9:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   323bc:	83 ec 0c             	sub    $0xc,%esp
   323bf:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   323c5:	50                   	push   %eax
   323c6:	e8 87 05 00 00       	call   32952 <cwrites>
   323cb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   323ce:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   323d5:	eb 4d                	jmp    32424 <progY+0x11a>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   323d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   323da:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   323e1:	85 c0                	test   %eax,%eax
   323e3:	74 0c                	je     323f1 <progY+0xe7>
   323e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   323e8:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   323ef:	eb 05                	jmp    323f6 <progY+0xec>
   323f1:	b8 a8 46 03 00       	mov    $0x346a8,%eax
   323f6:	83 ec 04             	sub    $0x4,%esp
   323f9:	50                   	push   %eax
   323fa:	68 af 46 03 00       	push   $0x346af
   323ff:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32405:	50                   	push   %eax
   32406:	e8 c6 06 00 00       	call   32ad1 <sprint>
   3240b:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   3240e:	83 ec 0c             	sub    $0xc,%esp
   32411:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32417:	50                   	push   %eax
   32418:	e8 35 05 00 00       	call   32952 <cwrites>
   3241d:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   32420:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   32424:	8b 45 ec             	mov    -0x14(%ebp),%eax
   32427:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   3242a:	7e ab                	jle    323d7 <progY+0xcd>
			}
			cwrites( "\n" );
   3242c:	83 ec 0c             	sub    $0xc,%esp
   3242f:	68 b3 46 03 00       	push   $0x346b3
   32434:	e8 19 05 00 00       	call   32952 <cwrites>
   32439:	83 c4 10             	add    $0x10,%esp
	}

	// report our presence
	pid_t pid = getpid();
   3243c:	e8 fa 05 00 00       	call   32a3b <getpid>
   32441:	89 45 dc             	mov    %eax,-0x24(%ebp)
	sprint( buf, " %c[%d]", ch, pid );
   32444:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   32448:	ff 75 dc             	push   -0x24(%ebp)
   3244b:	50                   	push   %eax
   3244c:	68 b5 46 03 00       	push   $0x346b5
   32451:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32457:	50                   	push   %eax
   32458:	e8 74 06 00 00       	call   32ad1 <sprint>
   3245d:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   32460:	83 ec 0c             	sub    $0xc,%esp
   32463:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32469:	50                   	push   %eax
   3246a:	e8 4c 05 00 00       	call   329bb <swrites>
   3246f:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   32472:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   32479:	eb 3c                	jmp    324b7 <progY+0x1ad>
		swrites( buf );
   3247b:	83 ec 0c             	sub    $0xc,%esp
   3247e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32484:	50                   	push   %eax
   32485:	e8 31 05 00 00       	call   329bb <swrites>
   3248a:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   3248d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   32494:	eb 04                	jmp    3249a <progY+0x190>
   32496:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   3249a:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   324a1:	7e f3                	jle    32496 <progY+0x18c>
		sleep( SEC_TO_MS(1) );
   324a3:	83 ec 0c             	sub    $0xc,%esp
   324a6:	68 e8 03 00 00       	push   $0x3e8
   324ab:	e8 83 05 00 00       	call   32a33 <sleep>
   324b0:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   324b3:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   324b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
   324ba:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   324bd:	7c bc                	jl     3247b <progY+0x171>
	}

	exit( 0 );
   324bf:	83 ec 0c             	sub    $0xc,%esp
   324c2:	6a 00                	push   $0x0
   324c4:	e8 3a 05 00 00       	call   32a03 <exit>
   324c9:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   324cc:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   324d1:	c9                   	leave  
   324d2:	c3                   	ret    

000324d3 <progZ>:
** Invoked as:	progZ  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progZ ) {
   324d3:	55                   	push   %ebp
   324d4:	89 e5                	mov    %esp,%ebp
   324d6:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	int count = 10;	  // default iteration count
   324dc:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'z';	  // default character to print
   324e3:	c6 45 f3 7a          	movb   $0x7a,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progZ" );
   324e7:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
   324ee:	00 00 00 
   324f1:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
   324f8:	00 00 00 
   324fb:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   32502:	00 00 00 
   32505:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
   3250c:	00 00 00 
   3250f:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   32516:	00 00 00 
   32519:	83 ec 0c             	sub    $0xc,%esp
   3251c:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   32522:	50                   	push   %eax
   32523:	6a 05                	push   $0x5
   32525:	6a 0d                	push   $0xd
   32527:	ff 75 08             	push   0x8(%ebp)
   3252a:	6a 03                	push   $0x3
   3252c:	e8 8e 01 00 00       	call   326bf <parseArgs>
   32531:	83 c4 20             	add    $0x20,%esp
   32534:	89 45 e0             	mov    %eax,-0x20(%ebp)
	switch( argc ) {
   32537:	83 7d e0 02          	cmpl   $0x2,-0x20(%ebp)
   3253b:	74 1d                	je     3255a <progZ+0x87>
   3253d:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
   32541:	75 28                	jne    3256b <progZ+0x98>
	case 3:	count = str2int( argv[2], 10 );
   32543:	8b 85 50 ff ff ff    	mov    -0xb0(%ebp),%eax
   32549:	83 ec 08             	sub    $0x8,%esp
   3254c:	6a 0a                	push   $0xa
   3254e:	50                   	push   %eax
   3254f:	e8 f2 07 00 00       	call   32d46 <str2int>
   32554:	83 c4 10             	add    $0x10,%esp
   32557:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   3255a:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
   32560:	0f b6 00             	movzbl (%eax),%eax
   32563:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   32566:	e9 9a 00 00 00       	jmp    32605 <progZ+0x132>
	default:
			sprint( buf, "?: argc %d, args: ", argc );
   3256b:	83 ec 04             	sub    $0x4,%esp
   3256e:	ff 75 e0             	push   -0x20(%ebp)
   32571:	68 bd 46 03 00       	push   $0x346bd
   32576:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3257c:	50                   	push   %eax
   3257d:	e8 4f 05 00 00       	call   32ad1 <sprint>
   32582:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   32585:	83 ec 0c             	sub    $0xc,%esp
   32588:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   3258e:	50                   	push   %eax
   3258f:	e8 be 03 00 00       	call   32952 <cwrites>
   32594:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   32597:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   3259e:	eb 4d                	jmp    325ed <progZ+0x11a>
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
   325a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
   325a3:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   325aa:	85 c0                	test   %eax,%eax
   325ac:	74 0c                	je     325ba <progZ+0xe7>
   325ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
   325b1:	8b 84 85 48 ff ff ff 	mov    -0xb8(%ebp,%eax,4),%eax
   325b8:	eb 05                	jmp    325bf <progZ+0xec>
   325ba:	b8 d0 46 03 00       	mov    $0x346d0,%eax
   325bf:	83 ec 04             	sub    $0x4,%esp
   325c2:	50                   	push   %eax
   325c3:	68 d7 46 03 00       	push   $0x346d7
   325c8:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   325ce:	50                   	push   %eax
   325cf:	e8 fd 04 00 00       	call   32ad1 <sprint>
   325d4:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   325d7:	83 ec 0c             	sub    $0xc,%esp
   325da:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   325e0:	50                   	push   %eax
   325e1:	e8 6c 03 00 00       	call   32952 <cwrites>
   325e6:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   325e9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   325ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
   325f0:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   325f3:	7e ab                	jle    325a0 <progZ+0xcd>
			}
			cwrites( "\n" );
   325f5:	83 ec 0c             	sub    $0xc,%esp
   325f8:	68 db 46 03 00       	push   $0x346db
   325fd:	e8 50 03 00 00       	call   32952 <cwrites>
   32602:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	pid_t pid = getpid();
   32605:	e8 31 04 00 00       	call   32a3b <getpid>
   3260a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	sprint( buf, " %c[%d]", ch, pid );
   3260d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   32611:	ff 75 dc             	push   -0x24(%ebp)
   32614:	50                   	push   %eax
   32615:	68 dd 46 03 00       	push   $0x346dd
   3261a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32620:	50                   	push   %eax
   32621:	e8 ab 04 00 00       	call   32ad1 <sprint>
   32626:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   32629:	83 ec 0c             	sub    $0xc,%esp
   3262c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32632:	50                   	push   %eax
   32633:	e8 83 03 00 00       	call   329bb <swrites>
   32638:	83 c4 10             	add    $0x10,%esp

	// iterate for a while; occasionally yield the CPU
	for( int i = 0; i < count ; ++i ) {
   3263b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   32642:	eb 5f                	jmp    326a3 <progZ+0x1d0>
		sprint( buf, " %c[%d]", ch, i );
   32644:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   32648:	ff 75 e8             	push   -0x18(%ebp)
   3264b:	50                   	push   %eax
   3264c:	68 dd 46 03 00       	push   $0x346dd
   32651:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32657:	50                   	push   %eax
   32658:	e8 74 04 00 00       	call   32ad1 <sprint>
   3265d:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   32660:	83 ec 0c             	sub    $0xc,%esp
   32663:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   32669:	50                   	push   %eax
   3266a:	e8 4c 03 00 00       	call   329bb <swrites>
   3266f:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   32672:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   32679:	eb 04                	jmp    3267f <progZ+0x1ac>
   3267b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   3267f:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   32686:	7e f3                	jle    3267b <progZ+0x1a8>
		if( i & 1 ) {
   32688:	8b 45 e8             	mov    -0x18(%ebp),%eax
   3268b:	83 e0 01             	and    $0x1,%eax
   3268e:	85 c0                	test   %eax,%eax
   32690:	74 0d                	je     3269f <progZ+0x1cc>
			sleep( 0 );
   32692:	83 ec 0c             	sub    $0xc,%esp
   32695:	6a 00                	push   $0x0
   32697:	e8 97 03 00 00       	call   32a33 <sleep>
   3269c:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   3269f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   326a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
   326a6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   326a9:	7c 99                	jl     32644 <progZ+0x171>
		}
	}

	exit( 0 );
   326ab:	83 ec 0c             	sub    $0xc,%esp
   326ae:	6a 00                	push   $0x0
   326b0:	e8 4e 03 00 00       	call   32a03 <exit>
   326b5:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   326b8:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   326bd:	c9                   	leave  
   326be:	c3                   	ret    

000326bf <parseArgs>:
** the beginnings of the argument strings, followed by a NULL pointer.
** Replaces the separator character with NUL characters.  Only converts
** the first n-1 entries, so the final entry will contain all remaining
** characters from the string.
*/
int parseArgs( int argc, char *args, char sep, int n, char *argv[] ) {
   326bf:	55                   	push   %ebp
   326c0:	89 e5                	mov    %esp,%ebp
   326c2:	83 ec 14             	sub    $0x14,%esp
   326c5:	8b 45 10             	mov    0x10(%ebp),%eax
   326c8:	88 45 ec             	mov    %al,-0x14(%ebp)
	** until either we hit the end of the string, or we fill up the
	** argv array.
	*/

	// NULL argument string -> no arguments!
	if( args == NULL ) {
   326cb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   326cf:	75 0a                	jne    326db <parseArgs+0x1c>
		return( -1 );
   326d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   326d6:	e9 85 00 00 00       	jmp    32760 <parseArgs+0xa1>
	}

	// argv must have argc+1 (or more) entries
	if( argc >= n ) {
   326db:	8b 45 08             	mov    0x8(%ebp),%eax
   326de:	3b 45 14             	cmp    0x14(%ebp),%eax
   326e1:	7c 07                	jl     326ea <parseArgs+0x2b>
		// expecting more arguments than we have argv[]
		// entries for???
		return( -1 );
   326e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   326e8:	eb 76                	jmp    32760 <parseArgs+0xa1>
	}

	int i;
	char *ptr = args;
   326ea:	8b 45 0c             	mov    0xc(%ebp),%eax
   326ed:	89 45 f8             	mov    %eax,-0x8(%ebp)

	// iterate through the arguments in the string
	for( i = 0 ; i < argc && i < (n-1); ++i ) {
   326f0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   326f7:	eb 4b                	jmp    32744 <parseArgs+0x85>

		// remember where the current argument begins
		argv[i] = ptr;
   326f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
   326fc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   32703:	8b 45 18             	mov    0x18(%ebp),%eax
   32706:	01 c2                	add    %eax,%edx
   32708:	8b 45 f8             	mov    -0x8(%ebp),%eax
   3270b:	89 02                	mov    %eax,(%edx)

		// find the next separator
		while( *ptr ) {
   3270d:	eb 1d                	jmp    3272c <parseArgs+0x6d>
			if( *ptr == sep ) {
   3270f:	8b 45 f8             	mov    -0x8(%ebp),%eax
   32712:	0f b6 00             	movzbl (%eax),%eax
   32715:	38 45 ec             	cmp    %al,-0x14(%ebp)
   32718:	75 0e                	jne    32728 <parseArgs+0x69>
				// found it - replace it and move on
				*ptr++ = '\0';
   3271a:	8b 45 f8             	mov    -0x8(%ebp),%eax
   3271d:	8d 50 01             	lea    0x1(%eax),%edx
   32720:	89 55 f8             	mov    %edx,-0x8(%ebp)
   32723:	c6 00 00             	movb   $0x0,(%eax)
				break;
   32726:	eb 0e                	jmp    32736 <parseArgs+0x77>
			} else {
				// didn't find it, so keep looking
				++ptr;
   32728:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
		while( *ptr ) {
   3272c:	8b 45 f8             	mov    -0x8(%ebp),%eax
   3272f:	0f b6 00             	movzbl (%eax),%eax
   32732:	84 c0                	test   %al,%al
   32734:	75 d9                	jne    3270f <parseArgs+0x50>
			}
		}

		// have we reached the end of the arg string?
		if( *ptr == '\0' ) {
   32736:	8b 45 f8             	mov    -0x8(%ebp),%eax
   32739:	0f b6 00             	movzbl (%eax),%eax
   3273c:	84 c0                	test   %al,%al
   3273e:	74 19                	je     32759 <parseArgs+0x9a>
	for( i = 0 ; i < argc && i < (n-1); ++i ) {
   32740:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   32744:	8b 45 fc             	mov    -0x4(%ebp),%eax
   32747:	3b 45 08             	cmp    0x8(%ebp),%eax
   3274a:	7d 0e                	jge    3275a <parseArgs+0x9b>
   3274c:	8b 45 14             	mov    0x14(%ebp),%eax
   3274f:	83 e8 01             	sub    $0x1,%eax
   32752:	39 45 fc             	cmp    %eax,-0x4(%ebp)
   32755:	7c a2                	jl     326f9 <parseArgs+0x3a>
   32757:	eb 01                	jmp    3275a <parseArgs+0x9b>
			break;
   32759:	90                   	nop

	// NULL pointer to terminate the argv array
	// argv[i] = NULL;

	// return the converted argument count
	return( i + 1 );
   3275a:	8b 45 fc             	mov    -0x4(%ebp),%eax
   3275d:	83 c0 01             	add    $0x1,%eax
}
   32760:	c9                   	leave  
   32761:	c3                   	ret    

00032762 <expand_args>:
** @param[in]  buf2   Source buffer
** @param[in]  max    Size of buf1
**
** @return The number of characters placed into buf1
*/
int expand_args( char *buf1, char *buf2, uint32_t max ) {
   32762:	55                   	push   %ebp
   32763:	89 e5                	mov    %esp,%ebp
   32765:	83 ec 10             	sub    $0x10,%esp
	uint32_t len = 0;
   32768:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	--max; // room for a NUL
   3276f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)

	while( *buf2 && len < max ) {
   32773:	e9 cf 00 00 00       	jmp    32847 <expand_args+0xe5>
		uchar_t ch = *buf2++;
   32778:	8b 45 0c             	mov    0xc(%ebp),%eax
   3277b:	8d 50 01             	lea    0x1(%eax),%edx
   3277e:	89 55 0c             	mov    %edx,0xc(%ebp)
   32781:	0f b6 00             	movzbl (%eax),%eax
   32784:	88 45 fb             	mov    %al,-0x5(%ebp)
		if( ch >= ' ' && ch < 0x7f ) {
   32787:	80 7d fb 1f          	cmpb   $0x1f,-0x5(%ebp)
   3278b:	76 1a                	jbe    327a7 <expand_args+0x45>
   3278d:	80 7d fb 7e          	cmpb   $0x7e,-0x5(%ebp)
   32791:	77 14                	ja     327a7 <expand_args+0x45>
			*buf1++ = ch;
   32793:	8b 45 08             	mov    0x8(%ebp),%eax
   32796:	8d 50 01             	lea    0x1(%eax),%edx
   32799:	89 55 08             	mov    %edx,0x8(%ebp)
   3279c:	0f b6 55 fb          	movzbl -0x5(%ebp),%edx
   327a0:	88 10                	mov    %dl,(%eax)
   327a2:	e9 9c 00 00 00       	jmp    32843 <expand_args+0xe1>
		} else {
			*buf1++ = '\\';
   327a7:	8b 45 08             	mov    0x8(%ebp),%eax
   327aa:	8d 50 01             	lea    0x1(%eax),%edx
   327ad:	89 55 08             	mov    %edx,0x8(%ebp)
   327b0:	c6 00 5c             	movb   $0x5c,(%eax)
			++len;  // one additional character
   327b3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			// we treat a few of these specially
			if( ch == '\r' )      *buf1++ = 'r';
   327b7:	80 7d fb 0d          	cmpb   $0xd,-0x5(%ebp)
   327bb:	75 0e                	jne    327cb <expand_args+0x69>
   327bd:	8b 45 08             	mov    0x8(%ebp),%eax
   327c0:	8d 50 01             	lea    0x1(%eax),%edx
   327c3:	89 55 08             	mov    %edx,0x8(%ebp)
   327c6:	c6 00 72             	movb   $0x72,(%eax)
   327c9:	eb 74                	jmp    3283f <expand_args+0xdd>
			else if( ch == '\t' ) *buf1++ = 't';
   327cb:	80 7d fb 09          	cmpb   $0x9,-0x5(%ebp)
   327cf:	75 0e                	jne    327df <expand_args+0x7d>
   327d1:	8b 45 08             	mov    0x8(%ebp),%eax
   327d4:	8d 50 01             	lea    0x1(%eax),%edx
   327d7:	89 55 08             	mov    %edx,0x8(%ebp)
   327da:	c6 00 74             	movb   $0x74,(%eax)
   327dd:	eb 60                	jmp    3283f <expand_args+0xdd>
			else if( ch == '\n' ) *buf1++ = 'n';
   327df:	80 7d fb 0a          	cmpb   $0xa,-0x5(%ebp)
   327e3:	75 0e                	jne    327f3 <expand_args+0x91>
   327e5:	8b 45 08             	mov    0x8(%ebp),%eax
   327e8:	8d 50 01             	lea    0x1(%eax),%edx
   327eb:	89 55 08             	mov    %edx,0x8(%ebp)
   327ee:	c6 00 6e             	movb   $0x6e,(%eax)
   327f1:	eb 4c                	jmp    3283f <expand_args+0xdd>
			else {
				// use a hex sequence
				*buf1++ = 'x';
   327f3:	8b 45 08             	mov    0x8(%ebp),%eax
   327f6:	8d 50 01             	lea    0x1(%eax),%edx
   327f9:	89 55 08             	mov    %edx,0x8(%ebp)
   327fc:	c6 00 78             	movb   $0x78,(%eax)
				*buf1++ = hexdigits[ (ch >> 4) & 0xf ];
   327ff:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
   32803:	c0 e8 04             	shr    $0x4,%al
   32806:	0f b6 c0             	movzbl %al,%eax
   32809:	83 e0 0f             	and    $0xf,%eax
   3280c:	89 c1                	mov    %eax,%ecx
   3280e:	8b 45 08             	mov    0x8(%ebp),%eax
   32811:	8d 50 01             	lea    0x1(%eax),%edx
   32814:	89 55 08             	mov    %edx,0x8(%ebp)
   32817:	0f b6 91 0c 47 03 00 	movzbl 0x3470c(%ecx),%edx
   3281e:	88 10                	mov    %dl,(%eax)
				*buf1++ = hexdigits[  ch       & 0xf ];
   32820:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
   32824:	83 e0 0f             	and    $0xf,%eax
   32827:	89 c1                	mov    %eax,%ecx
   32829:	8b 45 08             	mov    0x8(%ebp),%eax
   3282c:	8d 50 01             	lea    0x1(%eax),%edx
   3282f:	89 55 08             	mov    %edx,0x8(%ebp)
   32832:	0f b6 91 0c 47 03 00 	movzbl 0x3470c(%ecx),%edx
   32839:	88 10                	mov    %dl,(%eax)
				// two additional characters
				len += 2;
   3283b:	83 45 fc 02          	addl   $0x2,-0x4(%ebp)
			}
			++len;
   3283f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
		}
		++len; // added 1, or 2, or 4 characters
   32843:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
	while( *buf2 && len < max ) {
   32847:	8b 45 0c             	mov    0xc(%ebp),%eax
   3284a:	0f b6 00             	movzbl (%eax),%eax
   3284d:	84 c0                	test   %al,%al
   3284f:	74 0c                	je     3285d <expand_args+0xfb>
   32851:	8b 45 fc             	mov    -0x4(%ebp),%eax
   32854:	3b 45 10             	cmp    0x10(%ebp),%eax
   32857:	0f 82 1b ff ff ff    	jb     32778 <expand_args+0x16>
	}
	*buf1 = '\0';
   3285d:	8b 45 08             	mov    0x8(%ebp),%eax
   32860:	c6 00 00             	movb   $0x0,(%eax)

	return len;
   32863:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   32866:	c9                   	leave  
   32867:	c3                   	ret    

00032868 <spawn>:
** @param what  The program table index of the program to spawn
** @param args  The command-line argument vector for the new process
**
** @returns PID of the new process, or an error code
*/
int32_t spawn( uint32_t what, char *args ) {
   32868:	55                   	push   %ebp
   32869:	89 e5                	mov    %esp,%ebp
   3286b:	81 ec 28 02 00 00    	sub    $0x228,%esp

	// create the child
	pid_t pid = fork( PRIO_INHERIT );
   32871:	83 ec 0c             	sub    $0xc,%esp
   32874:	68 80 00 00 00       	push   $0x80
   32879:	e8 95 01 00 00       	call   32a13 <fork>
   3287e:	83 c4 10             	add    $0x10,%esp
   32881:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if( pid != 0 ) {
   32884:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   32888:	74 08                	je     32892 <spawn+0x2a>
		// failure, or we are the parent
		return( pid );
   3288a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   3288d:	e9 9d 00 00 00       	jmp    3292f <spawn+0xc7>
	}

	// try to get it going
	exec( what, args );
   32892:	83 ec 08             	sub    $0x8,%esp
   32895:	ff 75 0c             	push   0xc(%ebp)
   32898:	ff 75 08             	push   0x8(%ebp)
   3289b:	e8 7b 01 00 00       	call   32a1b <exec>
   328a0:	83 c4 10             	add    $0x10,%esp

	// uh-oh....

	// get our pid
	pid = getpid();
   328a3:	e8 93 01 00 00       	call   32a3b <getpid>
   328a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	
	// get the program name from the arg list
	char buf[512];
	char pname[16];
	char *bp = pname;
   328ab:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
   328b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while( *args >= ' ' && *args < 0x7f ) {
   328b4:	eb 17                	jmp    328cd <spawn+0x65>
		*bp++ = *args++;
   328b6:	8b 55 0c             	mov    0xc(%ebp),%edx
   328b9:	8d 42 01             	lea    0x1(%edx),%eax
   328bc:	89 45 0c             	mov    %eax,0xc(%ebp)
   328bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
   328c2:	8d 48 01             	lea    0x1(%eax),%ecx
   328c5:	89 4d f4             	mov    %ecx,-0xc(%ebp)
   328c8:	0f b6 12             	movzbl (%edx),%edx
   328cb:	88 10                	mov    %dl,(%eax)
	while( *args >= ' ' && *args < 0x7f ) {
   328cd:	8b 45 0c             	mov    0xc(%ebp),%eax
   328d0:	0f b6 00             	movzbl (%eax),%eax
   328d3:	3c 1f                	cmp    $0x1f,%al
   328d5:	7e 0a                	jle    328e1 <spawn+0x79>
   328d7:	8b 45 0c             	mov    0xc(%ebp),%eax
   328da:	0f b6 00             	movzbl (%eax),%eax
   328dd:	3c 7f                	cmp    $0x7f,%al
   328df:	75 d5                	jne    328b6 <spawn+0x4e>
	}
	*bp = '\0';
   328e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   328e4:	c6 00 00             	movb   $0x0,(%eax)

	// create the message
	sprint( buf, "Child %d exec(%08x,'%s') failed\n", pid, what, pname );
   328e7:	83 ec 0c             	sub    $0xc,%esp
   328ea:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
   328f0:	50                   	push   %eax
   328f1:	ff 75 08             	push   0x8(%ebp)
   328f4:	ff 75 f0             	push   -0x10(%ebp)
   328f7:	68 e8 46 03 00       	push   $0x346e8
   328fc:	8d 85 f0 fd ff ff    	lea    -0x210(%ebp),%eax
   32902:	50                   	push   %eax
   32903:	e8 c9 01 00 00       	call   32ad1 <sprint>
   32908:	83 c4 20             	add    $0x20,%esp

	cwrites( buf );
   3290b:	83 ec 0c             	sub    $0xc,%esp
   3290e:	8d 85 f0 fd ff ff    	lea    -0x210(%ebp),%eax
   32914:	50                   	push   %eax
   32915:	e8 38 00 00 00       	call   32952 <cwrites>
   3291a:	83 c4 10             	add    $0x10,%esp

	exit( S_ERROR );
   3291d:	83 ec 0c             	sub    $0xc,%esp
   32920:	6a ff                	push   $0xffffffff
   32922:	e8 dc 00 00 00       	call   32a03 <exit>
   32927:	83 c4 10             	add    $0x10,%esp

	return 42;    // shut the compiler up
   3292a:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   3292f:	c9                   	leave  
   32930:	c3                   	ret    

00032931 <cwritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int cwritech( char ch ) {
   32931:	55                   	push   %ebp
   32932:	89 e5                	mov    %esp,%ebp
   32934:	83 ec 18             	sub    $0x18,%esp
   32937:	8b 45 08             	mov    0x8(%ebp),%eax
   3293a:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_CIO,&ch,1) );
   3293d:	83 ec 04             	sub    $0x4,%esp
   32940:	6a 01                	push   $0x1
   32942:	8d 45 f4             	lea    -0xc(%ebp),%eax
   32945:	50                   	push   %eax
   32946:	6a 00                	push   $0x0
   32948:	e8 de 00 00 00       	call   32a2b <write>
   3294d:	83 c4 10             	add    $0x10,%esp
}
   32950:	c9                   	leave  
   32951:	c3                   	ret    

00032952 <cwrites>:
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str ) {
   32952:	55                   	push   %ebp
   32953:	89 e5                	mov    %esp,%ebp
   32955:	83 ec 18             	sub    $0x18,%esp
	int len = strlen(str);
   32958:	83 ec 0c             	sub    $0xc,%esp
   3295b:	ff 75 08             	push   0x8(%ebp)
   3295e:	e8 7d 05 00 00       	call   32ee0 <strlen>
   32963:	83 c4 10             	add    $0x10,%esp
   32966:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_CIO,str,len) );
   32969:	8b 45 f4             	mov    -0xc(%ebp),%eax
   3296c:	83 ec 04             	sub    $0x4,%esp
   3296f:	50                   	push   %eax
   32970:	ff 75 08             	push   0x8(%ebp)
   32973:	6a 00                	push   $0x0
   32975:	e8 b1 00 00 00       	call   32a2b <write>
   3297a:	83 c4 10             	add    $0x10,%esp
}
   3297d:	c9                   	leave  
   3297e:	c3                   	ret    

0003297f <cwrite>:
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @returns The return value from calling write()
*/
int cwrite( const char *buf, uint32_t leng ) {
   3297f:	55                   	push   %ebp
   32980:	89 e5                	mov    %esp,%ebp
   32982:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_CIO,buf,leng) );
   32985:	83 ec 04             	sub    $0x4,%esp
   32988:	ff 75 0c             	push   0xc(%ebp)
   3298b:	ff 75 08             	push   0x8(%ebp)
   3298e:	6a 00                	push   $0x0
   32990:	e8 96 00 00 00       	call   32a2b <write>
   32995:	83 c4 10             	add    $0x10,%esp
}
   32998:	c9                   	leave  
   32999:	c3                   	ret    

0003299a <swritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int swritech( char ch ) {
   3299a:	55                   	push   %ebp
   3299b:	89 e5                	mov    %esp,%ebp
   3299d:	83 ec 18             	sub    $0x18,%esp
   329a0:	8b 45 08             	mov    0x8(%ebp),%eax
   329a3:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_SIO,&ch,1) );
   329a6:	83 ec 04             	sub    $0x4,%esp
   329a9:	6a 01                	push   $0x1
   329ab:	8d 45 f4             	lea    -0xc(%ebp),%eax
   329ae:	50                   	push   %eax
   329af:	6a 01                	push   $0x1
   329b1:	e8 75 00 00 00       	call   32a2b <write>
   329b6:	83 c4 10             	add    $0x10,%esp
}
   329b9:	c9                   	leave  
   329ba:	c3                   	ret    

000329bb <swrites>:
**
** @param str The string to write
**
** @returns The return value from calling write()
*/
int swrites( const char *str ) {
   329bb:	55                   	push   %ebp
   329bc:	89 e5                	mov    %esp,%ebp
   329be:	83 ec 18             	sub    $0x18,%esp
	int len = strlen(str);
   329c1:	83 ec 0c             	sub    $0xc,%esp
   329c4:	ff 75 08             	push   0x8(%ebp)
   329c7:	e8 14 05 00 00       	call   32ee0 <strlen>
   329cc:	83 c4 10             	add    $0x10,%esp
   329cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_SIO,str,len) );
   329d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   329d5:	83 ec 04             	sub    $0x4,%esp
   329d8:	50                   	push   %eax
   329d9:	ff 75 08             	push   0x8(%ebp)
   329dc:	6a 01                	push   $0x1
   329de:	e8 48 00 00 00       	call   32a2b <write>
   329e3:	83 c4 10             	add    $0x10,%esp
}
   329e6:	c9                   	leave  
   329e7:	c3                   	ret    

000329e8 <swrite>:
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @returns The return value from calling write()
*/
int swrite( const char *buf, uint32_t leng ) {
   329e8:	55                   	push   %ebp
   329e9:	89 e5                	mov    %esp,%ebp
   329eb:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_SIO,buf,leng) );
   329ee:	83 ec 04             	sub    $0x4,%esp
   329f1:	ff 75 0c             	push   0xc(%ebp)
   329f4:	ff 75 08             	push   0x8(%ebp)
   329f7:	6a 01                	push   $0x1
   329f9:	e8 2d 00 00 00       	call   32a2b <write>
   329fe:	83 c4 10             	add    $0x10,%esp
}
   32a01:	c9                   	leave  
   32a02:	c3                   	ret    

00032a03 <exit>:

#
# "real" system calls
#

SYSCALL(exit)
   32a03:	b8 00 00 00 00       	mov    $0x0,%eax
   32a08:	cd 80                	int    $0x80
   32a0a:	c3                   	ret    

00032a0b <wait>:
SYSCALL(wait)
   32a0b:	b8 01 00 00 00       	mov    $0x1,%eax
   32a10:	cd 80                	int    $0x80
   32a12:	c3                   	ret    

00032a13 <fork>:
SYSCALL(fork)
   32a13:	b8 02 00 00 00       	mov    $0x2,%eax
   32a18:	cd 80                	int    $0x80
   32a1a:	c3                   	ret    

00032a1b <exec>:
SYSCALL(exec)
   32a1b:	b8 03 00 00 00       	mov    $0x3,%eax
   32a20:	cd 80                	int    $0x80
   32a22:	c3                   	ret    

00032a23 <read>:
SYSCALL(read)
   32a23:	b8 04 00 00 00       	mov    $0x4,%eax
   32a28:	cd 80                	int    $0x80
   32a2a:	c3                   	ret    

00032a2b <write>:
SYSCALL(write)
   32a2b:	b8 05 00 00 00       	mov    $0x5,%eax
   32a30:	cd 80                	int    $0x80
   32a32:	c3                   	ret    

00032a33 <sleep>:
SYSCALL(sleep)
   32a33:	b8 06 00 00 00       	mov    $0x6,%eax
   32a38:	cd 80                	int    $0x80
   32a3a:	c3                   	ret    

00032a3b <getpid>:
SYSCALL(getpid)
   32a3b:	b8 07 00 00 00       	mov    $0x7,%eax
   32a40:	cd 80                	int    $0x80
   32a42:	c3                   	ret    

00032a43 <gettime>:
SYSCALL(gettime)
   32a43:	b8 08 00 00 00       	mov    $0x8,%eax
   32a48:	cd 80                	int    $0x80
   32a4a:	c3                   	ret    

00032a4b <getprio>:
SYSCALL(getprio)
   32a4b:	b8 09 00 00 00       	mov    $0x9,%eax
   32a50:	cd 80                	int    $0x80
   32a52:	c3                   	ret    

00032a53 <bogus>:

#
# This is a bogus system call; it's here so that we can test
# our handling of out-of-range syscall codes in the syscall ISR.
#
SYSCALL(bogus)
   32a53:	b8 ad 0b 00 00       	mov    $0xbad,%eax
   32a58:	cd 80                	int    $0x80
   32a5a:	c3                   	ret    

00032a5b <fake_exit>:
#

	.globl	fake_exit
fake_exit:
	# alternate: could push a "fake exit" status
	subl	$12, %esp   # keep the stack aligned
   32a5b:	83 ec 0c             	sub    $0xc,%esp
	pushl	%eax        # termination status returned by main()
   32a5e:	50                   	push   %eax
	call	exit        # terminate this process
   32a5f:	e8 9f ff ff ff       	call   32a03 <exit>

00032a64 <hang>:
	# we shouldn't come back from that, but just in case...
hang:
	jmp	hang
   32a64:	eb fe                	jmp    32a64 <hang>

00032a66 <cvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value ) {
   32a66:	55                   	push   %ebp
   32a67:	89 e5                	mov    %esp,%ebp
   32a69:	83 ec 10             	sub    $0x10,%esp
	int chars_stored = 0;
   32a6c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   32a73:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   32a7a:	eb 44                	jmp    32ac0 <cvthex+0x5a>
		uint32_t val = value & 0xf0000000;
   32a7c:	8b 45 0c             	mov    0xc(%ebp),%eax
   32a7f:	25 00 00 00 f0       	and    $0xf0000000,%eax
   32a84:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   32a87:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   32a8b:	75 0c                	jne    32a99 <cvthex+0x33>
   32a8d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   32a91:	75 06                	jne    32a99 <cvthex+0x33>
   32a93:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   32a97:	75 1f                	jne    32ab8 <cvthex+0x52>
			++chars_stored;
   32a99:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   32a9d:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   32aa1:	8b 45 08             	mov    0x8(%ebp),%eax
   32aa4:	8d 50 01             	lea    0x1(%eax),%edx
   32aa7:	89 55 08             	mov    %edx,0x8(%ebp)
   32aaa:	8b 55 f4             	mov    -0xc(%ebp),%edx
   32aad:	81 c2 0c 47 03 00    	add    $0x3470c,%edx
   32ab3:	0f b6 12             	movzbl (%edx),%edx
   32ab6:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   32ab8:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   32abc:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   32ac0:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   32ac4:	7e b6                	jle    32a7c <cvthex+0x16>
	}

	*buf = '\0';
   32ac6:	8b 45 08             	mov    0x8(%ebp),%eax
   32ac9:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   32acc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   32acf:	c9                   	leave  
   32ad0:	c3                   	ret    

00032ad1 <sprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... ) {
   32ad1:	55                   	push   %ebp
   32ad2:	89 e5                	mov    %esp,%ebp
   32ad4:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   32ad7:	8d 45 0c             	lea    0xc(%ebp),%eax
   32ada:	83 c0 04             	add    $0x4,%eax
   32add:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   32ae0:	e9 3f 02 00 00       	jmp    32d24 <sprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   32ae5:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   32ae9:	0f 85 26 02 00 00    	jne    32d15 <sprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   32aef:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   32af6:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   32afd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   32b04:	8b 45 0c             	mov    0xc(%ebp),%eax
   32b07:	8d 50 01             	lea    0x1(%eax),%edx
   32b0a:	89 55 0c             	mov    %edx,0xc(%ebp)
   32b0d:	0f b6 00             	movzbl (%eax),%eax
   32b10:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   32b13:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   32b17:	75 16                	jne    32b2f <sprint+0x5e>
				leftadjust = 1;
   32b19:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   32b20:	8b 45 0c             	mov    0xc(%ebp),%eax
   32b23:	8d 50 01             	lea    0x1(%eax),%edx
   32b26:	89 55 0c             	mov    %edx,0xc(%ebp)
   32b29:	0f b6 00             	movzbl (%eax),%eax
   32b2c:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   32b2f:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   32b33:	75 40                	jne    32b75 <sprint+0xa4>
				padchar = '0';
   32b35:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   32b3c:	8b 45 0c             	mov    0xc(%ebp),%eax
   32b3f:	8d 50 01             	lea    0x1(%eax),%edx
   32b42:	89 55 0c             	mov    %edx,0xc(%ebp)
   32b45:	0f b6 00             	movzbl (%eax),%eax
   32b48:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   32b4b:	eb 28                	jmp    32b75 <sprint+0xa4>
				width *= 10;
   32b4d:	8b 55 e8             	mov    -0x18(%ebp),%edx
   32b50:	89 d0                	mov    %edx,%eax
   32b52:	c1 e0 02             	shl    $0x2,%eax
   32b55:	01 d0                	add    %edx,%eax
   32b57:	01 c0                	add    %eax,%eax
   32b59:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   32b5c:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   32b60:	83 e8 30             	sub    $0x30,%eax
   32b63:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   32b66:	8b 45 0c             	mov    0xc(%ebp),%eax
   32b69:	8d 50 01             	lea    0x1(%eax),%edx
   32b6c:	89 55 0c             	mov    %edx,0xc(%ebp)
   32b6f:	0f b6 00             	movzbl (%eax),%eax
   32b72:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   32b75:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   32b79:	7e 06                	jle    32b81 <sprint+0xb0>
   32b7b:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   32b7f:	7e cc                	jle    32b4d <sprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   32b81:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   32b85:	83 e8 63             	sub    $0x63,%eax
   32b88:	83 f8 15             	cmp    $0x15,%eax
   32b8b:	0f 87 93 01 00 00    	ja     32d24 <sprint+0x253>
   32b91:	8b 04 85 20 47 03 00 	mov    0x34720(,%eax,4),%eax
   32b98:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   32b9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32b9d:	8d 50 04             	lea    0x4(%eax),%edx
   32ba0:	89 55 f4             	mov    %edx,-0xc(%ebp)
   32ba3:	8b 00                	mov    (%eax),%eax
   32ba5:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   32ba8:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   32bac:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   32baf:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = padstr( dst, buf, 1, width, leftadjust, padchar );
   32bb3:	83 ec 08             	sub    $0x8,%esp
   32bb6:	ff 75 e4             	push   -0x1c(%ebp)
   32bb9:	ff 75 ec             	push   -0x14(%ebp)
   32bbc:	ff 75 e8             	push   -0x18(%ebp)
   32bbf:	6a 01                	push   $0x1
   32bc1:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32bc4:	50                   	push   %eax
   32bc5:	ff 75 08             	push   0x8(%ebp)
   32bc8:	e8 25 05 00 00       	call   330f2 <padstr>
   32bcd:	83 c4 20             	add    $0x20,%esp
   32bd0:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   32bd3:	e9 4c 01 00 00       	jmp    32d24 <sprint+0x253>

			case 'd':
				len = cvtdec( buf, *ap++ );
   32bd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32bdb:	8d 50 04             	lea    0x4(%eax),%edx
   32bde:	89 55 f4             	mov    %edx,-0xc(%ebp)
   32be1:	8b 00                	mov    (%eax),%eax
   32be3:	83 ec 08             	sub    $0x8,%esp
   32be6:	50                   	push   %eax
   32be7:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32bea:	50                   	push   %eax
   32beb:	e8 14 03 00 00       	call   32f04 <cvtdec>
   32bf0:	83 c4 10             	add    $0x10,%esp
   32bf3:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   32bf6:	83 ec 08             	sub    $0x8,%esp
   32bf9:	ff 75 e4             	push   -0x1c(%ebp)
   32bfc:	ff 75 ec             	push   -0x14(%ebp)
   32bff:	ff 75 e8             	push   -0x18(%ebp)
   32c02:	ff 75 e0             	push   -0x20(%ebp)
   32c05:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32c08:	50                   	push   %eax
   32c09:	ff 75 08             	push   0x8(%ebp)
   32c0c:	e8 e1 04 00 00       	call   330f2 <padstr>
   32c11:	83 c4 20             	add    $0x20,%esp
   32c14:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   32c17:	e9 08 01 00 00       	jmp    32d24 <sprint+0x253>

			case 's':
				str = (char *) (*ap++);
   32c1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32c1f:	8d 50 04             	lea    0x4(%eax),%edx
   32c22:	89 55 f4             	mov    %edx,-0xc(%ebp)
   32c25:	8b 00                	mov    (%eax),%eax
   32c27:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = padstr( dst, str, -1, width, leftadjust, padchar );
   32c2a:	83 ec 08             	sub    $0x8,%esp
   32c2d:	ff 75 e4             	push   -0x1c(%ebp)
   32c30:	ff 75 ec             	push   -0x14(%ebp)
   32c33:	ff 75 e8             	push   -0x18(%ebp)
   32c36:	6a ff                	push   $0xffffffff
   32c38:	ff 75 dc             	push   -0x24(%ebp)
   32c3b:	ff 75 08             	push   0x8(%ebp)
   32c3e:	e8 af 04 00 00       	call   330f2 <padstr>
   32c43:	83 c4 20             	add    $0x20,%esp
   32c46:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   32c49:	e9 d6 00 00 00       	jmp    32d24 <sprint+0x253>

			case 'x':
				len = cvthex( buf, *ap++ );
   32c4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32c51:	8d 50 04             	lea    0x4(%eax),%edx
   32c54:	89 55 f4             	mov    %edx,-0xc(%ebp)
   32c57:	8b 00                	mov    (%eax),%eax
   32c59:	83 ec 08             	sub    $0x8,%esp
   32c5c:	50                   	push   %eax
   32c5d:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32c60:	50                   	push   %eax
   32c61:	e8 00 fe ff ff       	call   32a66 <cvthex>
   32c66:	83 c4 10             	add    $0x10,%esp
   32c69:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   32c6c:	83 ec 08             	sub    $0x8,%esp
   32c6f:	ff 75 e4             	push   -0x1c(%ebp)
   32c72:	ff 75 ec             	push   -0x14(%ebp)
   32c75:	ff 75 e8             	push   -0x18(%ebp)
   32c78:	ff 75 e0             	push   -0x20(%ebp)
   32c7b:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32c7e:	50                   	push   %eax
   32c7f:	ff 75 08             	push   0x8(%ebp)
   32c82:	e8 6b 04 00 00       	call   330f2 <padstr>
   32c87:	83 c4 20             	add    $0x20,%esp
   32c8a:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   32c8d:	e9 92 00 00 00       	jmp    32d24 <sprint+0x253>

			case 'o':
				len = cvtoct( buf, *ap++ );
   32c92:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32c95:	8d 50 04             	lea    0x4(%eax),%edx
   32c98:	89 55 f4             	mov    %edx,-0xc(%ebp)
   32c9b:	8b 00                	mov    (%eax),%eax
   32c9d:	83 ec 08             	sub    $0x8,%esp
   32ca0:	50                   	push   %eax
   32ca1:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32ca4:	50                   	push   %eax
   32ca5:	e8 2e 03 00 00       	call   32fd8 <cvtoct>
   32caa:	83 c4 10             	add    $0x10,%esp
   32cad:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   32cb0:	83 ec 08             	sub    $0x8,%esp
   32cb3:	ff 75 e4             	push   -0x1c(%ebp)
   32cb6:	ff 75 ec             	push   -0x14(%ebp)
   32cb9:	ff 75 e8             	push   -0x18(%ebp)
   32cbc:	ff 75 e0             	push   -0x20(%ebp)
   32cbf:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32cc2:	50                   	push   %eax
   32cc3:	ff 75 08             	push   0x8(%ebp)
   32cc6:	e8 27 04 00 00       	call   330f2 <padstr>
   32ccb:	83 c4 20             	add    $0x20,%esp
   32cce:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   32cd1:	eb 51                	jmp    32d24 <sprint+0x253>

			case 'u':
				len = cvtuns( buf, *ap++ );
   32cd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32cd6:	8d 50 04             	lea    0x4(%eax),%edx
   32cd9:	89 55 f4             	mov    %edx,-0xc(%ebp)
   32cdc:	8b 00                	mov    (%eax),%eax
   32cde:	83 ec 08             	sub    $0x8,%esp
   32ce1:	50                   	push   %eax
   32ce2:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32ce5:	50                   	push   %eax
   32ce6:	e8 73 03 00 00       	call   3305e <cvtuns>
   32ceb:	83 c4 10             	add    $0x10,%esp
   32cee:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   32cf1:	83 ec 08             	sub    $0x8,%esp
   32cf4:	ff 75 e4             	push   -0x1c(%ebp)
   32cf7:	ff 75 ec             	push   -0x14(%ebp)
   32cfa:	ff 75 e8             	push   -0x18(%ebp)
   32cfd:	ff 75 e0             	push   -0x20(%ebp)
   32d00:	8d 45 d0             	lea    -0x30(%ebp),%eax
   32d03:	50                   	push   %eax
   32d04:	ff 75 08             	push   0x8(%ebp)
   32d07:	e8 e6 03 00 00       	call   330f2 <padstr>
   32d0c:	83 c4 20             	add    $0x20,%esp
   32d0f:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   32d12:	90                   	nop
   32d13:	eb 0f                	jmp    32d24 <sprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   32d15:	8b 45 08             	mov    0x8(%ebp),%eax
   32d18:	8d 50 01             	lea    0x1(%eax),%edx
   32d1b:	89 55 08             	mov    %edx,0x8(%ebp)
   32d1e:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   32d22:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   32d24:	8b 45 0c             	mov    0xc(%ebp),%eax
   32d27:	8d 50 01             	lea    0x1(%eax),%edx
   32d2a:	89 55 0c             	mov    %edx,0xc(%ebp)
   32d2d:	0f b6 00             	movzbl (%eax),%eax
   32d30:	88 45 f3             	mov    %al,-0xd(%ebp)
   32d33:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   32d37:	0f 85 a8 fd ff ff    	jne    32ae5 <sprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   32d3d:	8b 45 08             	mov    0x8(%ebp),%eax
   32d40:	c6 00 00             	movb   $0x0,(%eax)
}
   32d43:	90                   	nop
   32d44:	c9                   	leave  
   32d45:	c3                   	ret    

00032d46 <str2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base ) {
   32d46:	55                   	push   %ebp
   32d47:	89 e5                	mov    %esp,%ebp
   32d49:	57                   	push   %edi
   32d4a:	56                   	push   %esi
   32d4b:	53                   	push   %ebx
   32d4c:	83 ec 2c             	sub    $0x2c,%esp
   32d4f:	8b 5d 08             	mov    0x8(%ebp),%ebx
   32d52:	8b 7d 0c             	mov    0xc(%ebp),%edi
	register int num = 0;
   32d55:	be 00 00 00 00       	mov    $0x0,%esi
	register char bchar = '9';
   32d5a:	c6 45 d7 39          	movb   $0x39,-0x29(%ebp)
	int sign = 1;
   32d5e:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   32d65:	0f b6 03             	movzbl (%ebx),%eax
   32d68:	3c 2d                	cmp    $0x2d,%al
   32d6a:	75 0a                	jne    32d76 <str2int+0x30>
		sign = -1;
   32d6c:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		++str;
   32d73:	83 c3 01             	add    $0x1,%ebx
	}

	if( base != 10 ) {
   32d76:	83 ff 0a             	cmp    $0xa,%edi
   32d79:	0f 84 bf 00 00 00    	je     32e3e <str2int+0xf8>
		// fix the bchar
		bchar = '0' + base - 1;
   32d7f:	89 f8                	mov    %edi,%eax
   32d81:	83 c0 2f             	add    $0x2f,%eax
   32d84:	88 45 d7             	mov    %al,-0x29(%ebp)
		// skip any prefix
		if( base == 16 ) {
   32d87:	83 ff 10             	cmp    $0x10,%edi
   32d8a:	75 2f                	jne    32dbb <str2int+0x75>
			// bchar is wrong
			bchar = 'F';
   32d8c:	c6 45 d7 46          	movb   $0x46,-0x29(%ebp)
			// prefix: 0x or 0X
			if( *str == '0' && (*(str+1) == 'x' || *(str+1) == 'X') ) {
   32d90:	0f b6 03             	movzbl (%ebx),%eax
   32d93:	3c 30                	cmp    $0x30,%al
   32d95:	0f 85 a3 00 00 00    	jne    32e3e <str2int+0xf8>
   32d9b:	8d 43 01             	lea    0x1(%ebx),%eax
   32d9e:	0f b6 00             	movzbl (%eax),%eax
   32da1:	3c 78                	cmp    $0x78,%al
   32da3:	74 0e                	je     32db3 <str2int+0x6d>
   32da5:	8d 43 01             	lea    0x1(%ebx),%eax
   32da8:	0f b6 00             	movzbl (%eax),%eax
   32dab:	3c 58                	cmp    $0x58,%al
   32dad:	0f 85 8b 00 00 00    	jne    32e3e <str2int+0xf8>
				str += 2;
   32db3:	83 c3 02             	add    $0x2,%ebx
   32db6:	e9 83 00 00 00       	jmp    32e3e <str2int+0xf8>
			}
		} else if( base == 2 ) {
   32dbb:	83 ff 02             	cmp    $0x2,%edi
   32dbe:	75 7e                	jne    32e3e <str2int+0xf8>
			// prefix: 0b or 0B
			if( *str == '0' && (*(str+1) == 'b' || *(str+1) == 'B') ) {
   32dc0:	0f b6 03             	movzbl (%ebx),%eax
   32dc3:	3c 30                	cmp    $0x30,%al
   32dc5:	75 77                	jne    32e3e <str2int+0xf8>
   32dc7:	8d 43 01             	lea    0x1(%ebx),%eax
   32dca:	0f b6 00             	movzbl (%eax),%eax
   32dcd:	3c 62                	cmp    $0x62,%al
   32dcf:	74 0a                	je     32ddb <str2int+0x95>
   32dd1:	8d 43 01             	lea    0x1(%ebx),%eax
   32dd4:	0f b6 00             	movzbl (%eax),%eax
   32dd7:	3c 42                	cmp    $0x42,%al
   32dd9:	75 63                	jne    32e3e <str2int+0xf8>
				str += 2;
   32ddb:	83 c3 02             	add    $0x2,%ebx
			}
		}
	}

	// iterate through the characters
	while( *str ) {
   32dde:	eb 5e                	jmp    32e3e <str2int+0xf8>
		char ch = UCASE(*str);
   32de0:	0f b6 03             	movzbl (%ebx),%eax
   32de3:	3c 60                	cmp    $0x60,%al
   32de5:	7e 0f                	jle    32df6 <str2int+0xb0>
   32de7:	0f b6 03             	movzbl (%ebx),%eax
   32dea:	3c 7a                	cmp    $0x7a,%al
   32dec:	7f 08                	jg     32df6 <str2int+0xb0>
   32dee:	0f b6 03             	movzbl (%ebx),%eax
   32df1:	83 e0 df             	and    $0xffffffdf,%eax
   32df4:	eb 03                	jmp    32df9 <str2int+0xb3>
   32df6:	0f b6 03             	movzbl (%ebx),%eax
   32df9:	88 45 e3             	mov    %al,-0x1d(%ebp)
		char *ptr = strchr( hexdigits, ch );
   32dfc:	0f be 45 e3          	movsbl -0x1d(%ebp),%eax
   32e00:	83 ec 08             	sub    $0x8,%esp
   32e03:	50                   	push   %eax
   32e04:	68 0c 47 03 00       	push   $0x3470c
   32e09:	e8 4b 00 00 00       	call   32e59 <strchr>
   32e0e:	83 c4 10             	add    $0x10,%esp
   32e11:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( ptr == NULL ) {
   32e14:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   32e18:	74 2d                	je     32e47 <str2int+0x101>
			// impossible character
			break;
		} else if( *ptr > bchar ) {
   32e1a:	8b 45 dc             	mov    -0x24(%ebp),%eax
   32e1d:	0f b6 00             	movzbl (%eax),%eax
   32e20:	38 45 d7             	cmp    %al,-0x29(%ebp)
   32e23:	7c 25                	jl     32e4a <str2int+0x104>
			// outside the valid character range for this base
			break;
		}

		// convert character to integer
		int digit = ptr - hexdigits;
   32e25:	8b 45 dc             	mov    -0x24(%ebp),%eax
   32e28:	2d 0c 47 03 00       	sub    $0x3470c,%eax
   32e2d:	89 45 d8             	mov    %eax,-0x28(%ebp)
		num = num * base + digit;
   32e30:	89 f2                	mov    %esi,%edx
   32e32:	0f af d7             	imul   %edi,%edx
   32e35:	8b 45 d8             	mov    -0x28(%ebp),%eax
   32e38:	8d 34 02             	lea    (%edx,%eax,1),%esi
		++str;
   32e3b:	83 c3 01             	add    $0x1,%ebx
	while( *str ) {
   32e3e:	0f b6 03             	movzbl (%ebx),%eax
   32e41:	84 c0                	test   %al,%al
   32e43:	75 9b                	jne    32de0 <str2int+0x9a>
   32e45:	eb 04                	jmp    32e4b <str2int+0x105>
			break;
   32e47:	90                   	nop
   32e48:	eb 01                	jmp    32e4b <str2int+0x105>
			break;
   32e4a:	90                   	nop
	}

	// return the converted value
	return( num * sign );
   32e4b:	89 f0                	mov    %esi,%eax
   32e4d:	0f af 45 e4          	imul   -0x1c(%ebp),%eax
}
   32e51:	8d 65 f4             	lea    -0xc(%ebp),%esp
   32e54:	5b                   	pop    %ebx
   32e55:	5e                   	pop    %esi
   32e56:	5f                   	pop    %edi
   32e57:	5d                   	pop    %ebp
   32e58:	c3                   	ret    

00032e59 <strchr>:
** @param str[in] The string to examine
** @param ch[in]  The character to look for
**
** @return Pointer to the first 'ch' in 'str', or NULL
*/
char *strchr( register const char *str, register char ch ) {
   32e59:	55                   	push   %ebp
   32e5a:	89 e5                	mov    %esp,%ebp
   32e5c:	8b 45 08             	mov    0x8(%ebp),%eax
   32e5f:	8b 55 0c             	mov    0xc(%ebp),%edx
   32e62:	89 d1                	mov    %edx,%ecx

	if( str == NULL ) {
   32e64:	85 c0                	test   %eax,%eax
   32e66:	75 13                	jne    32e7b <strchr+0x22>
		return NULL;
   32e68:	b8 00 00 00 00       	mov    $0x0,%eax
   32e6d:	eb 18                	jmp    32e87 <strchr+0x2e>
	}

	// scan from the beginning of the string
	while( *str ) {
		if( *str == ch ) {
   32e6f:	0f b6 10             	movzbl (%eax),%edx
   32e72:	38 d1                	cmp    %dl,%cl
   32e74:	75 02                	jne    32e78 <strchr+0x1f>
			return (char *) str;
   32e76:	eb 0f                	jmp    32e87 <strchr+0x2e>
		}
		++str;
   32e78:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   32e7b:	0f b6 10             	movzbl (%eax),%edx
   32e7e:	84 d2                	test   %dl,%dl
   32e80:	75 ed                	jne    32e6f <strchr+0x16>
	}

	return NULL;
   32e82:	b8 00 00 00 00       	mov    $0x0,%eax
}
   32e87:	5d                   	pop    %ebp
   32e88:	c3                   	ret    

00032e89 <strrchr>:
** @param str[in] The string to examine
** @param ch[in]  The character to look for
**
** @return Pointer to the first 'ch' in 'str', or NULL
*/
char *strrchr( register const char *str, register char ch ) {
   32e89:	55                   	push   %ebp
   32e8a:	89 e5                	mov    %esp,%ebp
   32e8c:	56                   	push   %esi
   32e8d:	53                   	push   %ebx
   32e8e:	83 ec 10             	sub    $0x10,%esp
   32e91:	8b 75 08             	mov    0x8(%ebp),%esi
   32e94:	8b 45 0c             	mov    0xc(%ebp),%eax
   32e97:	88 45 f7             	mov    %al,-0x9(%ebp)
	register char *ptr = (char *) str;
   32e9a:	89 f3                	mov    %esi,%ebx

	if( str == NULL ) {
   32e9c:	85 f6                	test   %esi,%esi
   32e9e:	75 07                	jne    32ea7 <strrchr+0x1e>
		return NULL;
   32ea0:	b8 00 00 00 00       	mov    $0x0,%eax
   32ea5:	eb 32                	jmp    32ed9 <strrchr+0x50>
	}

	// find the NUL, and back up one position
	ptr += strlen(str) - 1;
   32ea7:	83 ec 0c             	sub    $0xc,%esp
   32eaa:	56                   	push   %esi
   32eab:	e8 30 00 00 00       	call   32ee0 <strlen>
   32eb0:	83 c4 10             	add    $0x10,%esp
   32eb3:	83 e8 01             	sub    $0x1,%eax
   32eb6:	01 c3                	add    %eax,%ebx

	// scan backward
	while( ptr >= str && *ptr ) {
   32eb8:	eb 0f                	jmp    32ec9 <strrchr+0x40>
		if( *ptr == ch ) {
   32eba:	0f b6 03             	movzbl (%ebx),%eax
   32ebd:	38 45 f7             	cmp    %al,-0x9(%ebp)
   32ec0:	75 04                	jne    32ec6 <strrchr+0x3d>
			return ptr;
   32ec2:	89 d8                	mov    %ebx,%eax
   32ec4:	eb 13                	jmp    32ed9 <strrchr+0x50>
		}
		--ptr;
   32ec6:	83 eb 01             	sub    $0x1,%ebx
	while( ptr >= str && *ptr ) {
   32ec9:	39 f3                	cmp    %esi,%ebx
   32ecb:	72 07                	jb     32ed4 <strrchr+0x4b>
   32ecd:	0f b6 03             	movzbl (%ebx),%eax
   32ed0:	84 c0                	test   %al,%al
   32ed2:	75 e6                	jne    32eba <strrchr+0x31>
	}

	return NULL;
   32ed4:	b8 00 00 00 00       	mov    $0x0,%eax
}
   32ed9:	8d 65 f8             	lea    -0x8(%ebp),%esp
   32edc:	5b                   	pop    %ebx
   32edd:	5e                   	pop    %esi
   32ede:	5d                   	pop    %ebp
   32edf:	c3                   	ret    

00032ee0 <strlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str ) {
   32ee0:	55                   	push   %ebp
   32ee1:	89 e5                	mov    %esp,%ebp
   32ee3:	53                   	push   %ebx
   32ee4:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   32ee7:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   32eec:	eb 03                	jmp    32ef1 <strlen+0x11>
		++len;
   32eee:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   32ef1:	89 d0                	mov    %edx,%eax
   32ef3:	8d 50 01             	lea    0x1(%eax),%edx
   32ef6:	0f b6 00             	movzbl (%eax),%eax
   32ef9:	84 c0                	test   %al,%al
   32efb:	75 f1                	jne    32eee <strlen+0xe>
	}

	return( len );
   32efd:	89 d8                	mov    %ebx,%eax
}
   32eff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   32f02:	c9                   	leave  
   32f03:	c3                   	ret    

00032f04 <cvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value ) {
   32f04:	55                   	push   %ebp
   32f05:	89 e5                	mov    %esp,%ebp
   32f07:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   32f0a:	8b 45 08             	mov    0x8(%ebp),%eax
   32f0d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   32f10:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   32f14:	79 0f                	jns    32f25 <cvtdec+0x21>
		*bp++ = '-';
   32f16:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32f19:	8d 50 01             	lea    0x1(%eax),%edx
   32f1c:	89 55 f4             	mov    %edx,-0xc(%ebp)
   32f1f:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   32f22:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = cvtdec0( bp, value );
   32f25:	83 ec 08             	sub    $0x8,%esp
   32f28:	ff 75 0c             	push   0xc(%ebp)
   32f2b:	ff 75 f4             	push   -0xc(%ebp)
   32f2e:	e8 14 00 00 00       	call   32f47 <cvtdec0>
   32f33:	83 c4 10             	add    $0x10,%esp
   32f36:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   32f39:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32f3c:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   32f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   32f42:	2b 45 08             	sub    0x8(%ebp),%eax
}
   32f45:	c9                   	leave  
   32f46:	c3                   	ret    

00032f47 <cvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value ) {
   32f47:	55                   	push   %ebp
   32f48:	89 e5                	mov    %esp,%ebp
   32f4a:	53                   	push   %ebx
   32f4b:	83 ec 14             	sub    $0x14,%esp
	int quotient;

	quotient = value / 10;
   32f4e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   32f51:	ba 67 66 66 66       	mov    $0x66666667,%edx
   32f56:	89 c8                	mov    %ecx,%eax
   32f58:	f7 ea                	imul   %edx
   32f5a:	89 d0                	mov    %edx,%eax
   32f5c:	c1 f8 02             	sar    $0x2,%eax
   32f5f:	c1 f9 1f             	sar    $0x1f,%ecx
   32f62:	89 ca                	mov    %ecx,%edx
   32f64:	29 d0                	sub    %edx,%eax
   32f66:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   32f69:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   32f6d:	79 0e                	jns    32f7d <cvtdec0+0x36>
		quotient = 214748364;
   32f6f:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   32f76:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   32f7d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   32f81:	74 14                	je     32f97 <cvtdec0+0x50>
		buf = cvtdec0( buf, quotient );
   32f83:	83 ec 08             	sub    $0x8,%esp
   32f86:	ff 75 f4             	push   -0xc(%ebp)
   32f89:	ff 75 08             	push   0x8(%ebp)
   32f8c:	e8 b6 ff ff ff       	call   32f47 <cvtdec0>
   32f91:	83 c4 10             	add    $0x10,%esp
   32f94:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   32f97:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   32f9a:	ba 67 66 66 66       	mov    $0x66666667,%edx
   32f9f:	89 c8                	mov    %ecx,%eax
   32fa1:	f7 ea                	imul   %edx
   32fa3:	89 d0                	mov    %edx,%eax
   32fa5:	c1 f8 02             	sar    $0x2,%eax
   32fa8:	89 cb                	mov    %ecx,%ebx
   32faa:	c1 fb 1f             	sar    $0x1f,%ebx
   32fad:	29 d8                	sub    %ebx,%eax
   32faf:	89 c2                	mov    %eax,%edx
   32fb1:	89 d0                	mov    %edx,%eax
   32fb3:	c1 e0 02             	shl    $0x2,%eax
   32fb6:	01 d0                	add    %edx,%eax
   32fb8:	01 c0                	add    %eax,%eax
   32fba:	29 c1                	sub    %eax,%ecx
   32fbc:	89 ca                	mov    %ecx,%edx
   32fbe:	89 d0                	mov    %edx,%eax
   32fc0:	8d 48 30             	lea    0x30(%eax),%ecx
   32fc3:	8b 45 08             	mov    0x8(%ebp),%eax
   32fc6:	8d 50 01             	lea    0x1(%eax),%edx
   32fc9:	89 55 08             	mov    %edx,0x8(%ebp)
   32fcc:	89 ca                	mov    %ecx,%edx
   32fce:	88 10                	mov    %dl,(%eax)
	return buf;
   32fd0:	8b 45 08             	mov    0x8(%ebp),%eax
}
   32fd3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   32fd6:	c9                   	leave  
   32fd7:	c3                   	ret    

00032fd8 <cvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value ) {
   32fd8:	55                   	push   %ebp
   32fd9:	89 e5                	mov    %esp,%ebp
   32fdb:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   32fde:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   32fe5:	8b 45 08             	mov    0x8(%ebp),%eax
   32fe8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   32feb:	8b 45 0c             	mov    0xc(%ebp),%eax
   32fee:	25 00 00 00 c0       	and    $0xc0000000,%eax
   32ff3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   32ff6:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   32ffa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   33001:	eb 47                	jmp    3304a <cvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   33003:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   33007:	74 0c                	je     33015 <cvtoct+0x3d>
   33009:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   3300d:	75 06                	jne    33015 <cvtoct+0x3d>
   3300f:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   33013:	74 1e                	je     33033 <cvtoct+0x5b>
			chars_stored = 1;
   33015:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   3301c:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   33020:	8b 45 f0             	mov    -0x10(%ebp),%eax
   33023:	8d 48 30             	lea    0x30(%eax),%ecx
   33026:	8b 45 f4             	mov    -0xc(%ebp),%eax
   33029:	8d 50 01             	lea    0x1(%eax),%edx
   3302c:	89 55 f4             	mov    %edx,-0xc(%ebp)
   3302f:	89 ca                	mov    %ecx,%edx
   33031:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   33033:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   33037:	8b 45 0c             	mov    0xc(%ebp),%eax
   3303a:	25 00 00 00 e0       	and    $0xe0000000,%eax
   3303f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   33042:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   33046:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   3304a:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   3304e:	7e b3                	jle    33003 <cvtoct+0x2b>
	}
	*bp = '\0';
   33050:	8b 45 f4             	mov    -0xc(%ebp),%eax
   33053:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   33056:	8b 45 f4             	mov    -0xc(%ebp),%eax
   33059:	2b 45 08             	sub    0x8(%ebp),%eax
}
   3305c:	c9                   	leave  
   3305d:	c3                   	ret    

0003305e <cvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value ) {
   3305e:	55                   	push   %ebp
   3305f:	89 e5                	mov    %esp,%ebp
   33061:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   33064:	8b 45 08             	mov    0x8(%ebp),%eax
   33067:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = cvtuns0( bp, value );
   3306a:	83 ec 08             	sub    $0x8,%esp
   3306d:	ff 75 0c             	push   0xc(%ebp)
   33070:	ff 75 f4             	push   -0xc(%ebp)
   33073:	e8 14 00 00 00       	call   3308c <cvtuns0>
   33078:	83 c4 10             	add    $0x10,%esp
   3307b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   3307e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   33081:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   33084:	8b 45 f4             	mov    -0xc(%ebp),%eax
   33087:	2b 45 08             	sub    0x8(%ebp),%eax
}
   3308a:	c9                   	leave  
   3308b:	c3                   	ret    

0003308c <cvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value ) {
   3308c:	55                   	push   %ebp
   3308d:	89 e5                	mov    %esp,%ebp
   3308f:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   33092:	8b 45 0c             	mov    0xc(%ebp),%eax
   33095:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   3309a:	f7 e2                	mul    %edx
   3309c:	89 d0                	mov    %edx,%eax
   3309e:	c1 e8 03             	shr    $0x3,%eax
   330a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   330a4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   330a8:	74 15                	je     330bf <cvtuns0+0x33>
		buf = cvtdec0( buf, quotient );
   330aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
   330ad:	83 ec 08             	sub    $0x8,%esp
   330b0:	50                   	push   %eax
   330b1:	ff 75 08             	push   0x8(%ebp)
   330b4:	e8 8e fe ff ff       	call   32f47 <cvtdec0>
   330b9:	83 c4 10             	add    $0x10,%esp
   330bc:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   330bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   330c2:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   330c7:	89 c8                	mov    %ecx,%eax
   330c9:	f7 e2                	mul    %edx
   330cb:	c1 ea 03             	shr    $0x3,%edx
   330ce:	89 d0                	mov    %edx,%eax
   330d0:	c1 e0 02             	shl    $0x2,%eax
   330d3:	01 d0                	add    %edx,%eax
   330d5:	01 c0                	add    %eax,%eax
   330d7:	29 c1                	sub    %eax,%ecx
   330d9:	89 ca                	mov    %ecx,%edx
   330db:	89 d0                	mov    %edx,%eax
   330dd:	8d 48 30             	lea    0x30(%eax),%ecx
   330e0:	8b 45 08             	mov    0x8(%ebp),%eax
   330e3:	8d 50 01             	lea    0x1(%eax),%edx
   330e6:	89 55 08             	mov    %edx,0x8(%ebp)
   330e9:	89 ca                	mov    %ecx,%edx
   330eb:	88 10                	mov    %dl,(%eax)
	return buf;
   330ed:	8b 45 08             	mov    0x8(%ebp),%eax
}
   330f0:	c9                   	leave  
   330f1:	c3                   	ret    

000330f2 <padstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   330f2:	55                   	push   %ebp
   330f3:	89 e5                	mov    %esp,%ebp
   330f5:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   330f8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   330fc:	79 11                	jns    3310f <padstr+0x1d>
		len = strlen( str );
   330fe:	83 ec 0c             	sub    $0xc,%esp
   33101:	ff 75 0c             	push   0xc(%ebp)
   33104:	e8 d7 fd ff ff       	call   32ee0 <strlen>
   33109:	83 c4 10             	add    $0x10,%esp
   3310c:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   3310f:	8b 45 14             	mov    0x14(%ebp),%eax
   33112:	2b 45 10             	sub    0x10(%ebp),%eax
   33115:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   33118:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   3311c:	7e 1d                	jle    3313b <padstr+0x49>
   3311e:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   33122:	75 17                	jne    3313b <padstr+0x49>
		dst = pad( dst, extra, padchar );
   33124:	83 ec 04             	sub    $0x4,%esp
   33127:	ff 75 1c             	push   0x1c(%ebp)
   3312a:	ff 75 f0             	push   -0x10(%ebp)
   3312d:	ff 75 08             	push   0x8(%ebp)
   33130:	e8 5a 00 00 00       	call   3318f <pad>
   33135:	83 c4 10             	add    $0x10,%esp
   33138:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   3313b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   33142:	eb 1b                	jmp    3315f <padstr+0x6d>
		*dst++ = str[i];
   33144:	8b 55 f4             	mov    -0xc(%ebp),%edx
   33147:	8b 45 0c             	mov    0xc(%ebp),%eax
   3314a:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   3314d:	8b 45 08             	mov    0x8(%ebp),%eax
   33150:	8d 50 01             	lea    0x1(%eax),%edx
   33153:	89 55 08             	mov    %edx,0x8(%ebp)
   33156:	0f b6 11             	movzbl (%ecx),%edx
   33159:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   3315b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   3315f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   33162:	3b 45 10             	cmp    0x10(%ebp),%eax
   33165:	7c dd                	jl     33144 <padstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   33167:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   3316b:	7e 1d                	jle    3318a <padstr+0x98>
   3316d:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   33171:	74 17                	je     3318a <padstr+0x98>
		dst = pad( dst, extra, padchar );
   33173:	83 ec 04             	sub    $0x4,%esp
   33176:	ff 75 1c             	push   0x1c(%ebp)
   33179:	ff 75 f0             	push   -0x10(%ebp)
   3317c:	ff 75 08             	push   0x8(%ebp)
   3317f:	e8 0b 00 00 00       	call   3318f <pad>
   33184:	83 c4 10             	add    $0x10,%esp
   33187:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   3318a:	8b 45 08             	mov    0x8(%ebp),%eax
}
   3318d:	c9                   	leave  
   3318e:	c3                   	ret    

0003318f <pad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar ) {
   3318f:	55                   	push   %ebp
   33190:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   33192:	eb 12                	jmp    331a6 <pad+0x17>
		*dst++ = (char) padchar;
   33194:	8b 45 08             	mov    0x8(%ebp),%eax
   33197:	8d 50 01             	lea    0x1(%eax),%edx
   3319a:	89 55 08             	mov    %edx,0x8(%ebp)
   3319d:	8b 55 10             	mov    0x10(%ebp),%edx
   331a0:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   331a2:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   331a6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   331aa:	7f e8                	jg     33194 <pad+0x5>
	}
	return dst;
   331ac:	8b 45 08             	mov    0x8(%ebp),%eax
}
   331af:	5d                   	pop    %ebp
   331b0:	c3                   	ret    
